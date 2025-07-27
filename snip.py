import tkinter as tk
import os
import subprocess
from PIL import Image, ImageTk

# --- Dependency Check ---
def check_dependencies():
    """Checks for required command-line tools."""
    dependencies = ["scrot", "xclip"]
    missing = []
    for dep in dependencies:
        if subprocess.run(["which", dep], capture_output=True, text=True).returncode != 0:
            missing.append(dep)
    if missing:
        print(f"Error: Missing required dependencies: {', '.join(missing)}.")
        print(f"Please install them (e.g., 'sudo apt-get install {', '.join(missing)}') and try again.")
        exit(1)

try:
    from PIL import Image, ImageTk
except ImportError:
    print("Error: The 'Pillow' library is not installed.")
    print("Please install it using: pip install Pillow")
    exit(1)


class SnippingTool:
    def __init__(self, root):
        self.root = root
        self.root.overrideredirect(True)
        screen_width = self.root.winfo_screenwidth()
        screen_height = self.root.winfo_screenheight()
        self.root.geometry(f'{screen_width}x{screen_height}+0+0')
        self.root.wait_visibility(self.root) # Wait for the window to be created
        self.root.attributes("-alpha", 0.0) # Make it fully transparent initially

        # 1. Take a screenshot of the entire screen
        self.screenshot_path = "/tmp/full_screen_snip.png"
        # Hide the root window before taking the screenshot
        self.root.withdraw()
        subprocess.run(["scrot", "-o", self.screenshot_path], check=True)
        self.root.deiconify() # Show the window again

        # 2. Display the screenshot in a fullscreen window
        self.image = Image.open(self.screenshot_path)
        self.tk_image = ImageTk.PhotoImage(self.image)

        self.canvas = tk.Canvas(self.root, cursor="cross")
        self.canvas.pack(fill=tk.BOTH, expand=tk.YES)
        self.canvas.create_image(0, 0, anchor=tk.NW, image=self.tk_image)

        # Make the window visible again after a short delay
        self.root.after(100, lambda: self.root.attributes("-alpha", 1.0))

        self.start_x = None
        self.start_y = None
        self.rect = None

        self.canvas.bind("<ButtonPress-1>", self.on_button_press)
        self.canvas.bind("<B1-Motion>", self.on_mouse_drag)
        self.canvas.bind("<ButtonRelease-1>", self.on_button_release)
        self.root.bind("<Escape>", self.exit)


    def on_button_press(self, event):
        self.start_x = self.canvas.canvasx(event.x)
        self.start_y = self.canvas.canvasy(event.y)
        if self.rect:
            self.canvas.delete(self.rect)
        self.rect = self.canvas.create_rectangle(
            self.start_x, self.start_y, self.start_x, self.start_y,
            outline='red', width=2, dash=(5, 5)
        )

    def on_mouse_drag(self, event):
        cur_x = self.canvas.canvasx(event.x)
        cur_y = self.canvas.canvasy(event.y)
        self.canvas.coords(self.rect, self.start_x, self.start_y, cur_x, cur_y)

    def on_button_release(self, event):
        end_x = self.canvas.canvasx(event.x)
        end_y = self.canvas.canvasy(event.y)
        self.process_selection(end_x, end_y)

    def process_selection(self, end_x, end_y):
        self.root.withdraw() # Make the window invisible
        self.root.after(100, self.process_and_exit, end_x, end_y)

        def process_and_exit(self, end_x, end_y):
        x1 = int(min(self.start_x, end_x))
        y1 = int(min(self.start_y, end_y))
        x2 = int(max(self.start_x, end_x))
        y2 = int(max(self.start_y, end_y))

        if x1 < x2 and y1 < y2:
            # 4. Crop the original screenshot
            cropped_image = self.image.crop((x1, y1, x2, y2))
            cropped_path = "/tmp/cropped_snip.png"
            cropped_image.save(cropped_path, "PNG")

            # 5. Copy the cropped image to the clipboard
            try:
                subprocess.run(
                    f"xclip -selection clipboard -t image/png -i {cropped_path}",
                    shell=True, check=True
                )
            finally:
                # 6. Clean up temporary files
                os.remove(cropped_path)
                os.remove(self.screenshot_path)
        self.root.destroy()

    def exit(self, event=None):
        self.root.destroy()
        os.remove(self.screenshot_path)


if __name__ == "__main__":
    check_dependencies()
    main_root = tk.Tk()
    app = SnippingTool(main_root)
    main_root.mainloop()