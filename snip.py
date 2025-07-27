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
        self.screen_width = self.root.winfo_screenwidth()
        self.screen_height = self.root.winfo_screenheight()
        self.root.geometry(f'{self.screen_width}x{self.screen_height}+0+0')
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
        
        # Create darkened version of the image
        self.darkened_image = self.image.point(lambda p: int(p * 0.3))  # Darken to 30%
        self.darkened_tk_image = ImageTk.PhotoImage(self.darkened_image)

        self.canvas = tk.Canvas(self.root, cursor="cross", highlightthickness=0)
        self.canvas.pack(fill=tk.BOTH, expand=tk.YES)
        
        # Display the darkened image initially
        self.background_image = self.canvas.create_image(0, 0, anchor=tk.NW, image=self.darkened_tk_image)
        
        # Create overlay for the dark effect
        self.overlay = self.canvas.create_rectangle(0, 0, self.screen_width, self.screen_height, 
                                                   fill='black', stipple='gray50', outline='')

        # Make the window visible again after a short delay
        self.root.after(100, lambda: self.root.attributes("-alpha", 1.0))

        self.start_x = None
        self.start_y = None
        self.selection_rect = None
        self.selection_image = None
        self.selection_border = None

        self.canvas.bind("<ButtonPress-1>", self.on_button_press)
        self.canvas.bind("<B1-Motion>", self.on_mouse_drag)
        self.canvas.bind("<ButtonRelease-1>", self.on_button_release)
        self.root.bind("<Escape>", self.exit)


    def on_button_press(self, event):
        self.start_x = self.canvas.canvasx(event.x)
        self.start_y = self.canvas.canvasy(event.y)
        
        # Clear any existing selection
        self.clear_selection()
        
        # Create initial selection rectangle (invisible for now)
        self.selection_rect = self.canvas.create_rectangle(
            self.start_x, self.start_y, self.start_x, self.start_y,
            outline='', fill='', width=0
        )

    def on_mouse_drag(self, event):
        cur_x = self.canvas.canvasx(event.x)
        cur_y = self.canvas.canvasy(event.y)
        
        # Update selection rectangle coordinates
        self.canvas.coords(self.selection_rect, self.start_x, self.start_y, cur_x, cur_y)
        
        # Update the selection display
        self.update_selection(self.start_x, self.start_y, cur_x, cur_y)

    def on_button_release(self, event):
        end_x = self.canvas.canvasx(event.x)
        end_y = self.canvas.canvasy(event.y)
        self.process_selection(end_x, end_y)

    def process_selection(self, end_x, end_y):
        self.root.withdraw() # Make the window invisible
        self.root.after(100, self.process_and_exit, end_x, end_y)

    def clear_selection(self):
        """Clear any existing selection elements"""
        if self.selection_image:
            self.canvas.delete(self.selection_image)
            self.selection_image = None
        if self.selection_border:
            self.canvas.delete(self.selection_border)
            self.selection_border = None
    
    def update_selection(self, x1, y1, x2, y2):
        """Update the selection display with normal brightness and white border"""
        # Clear previous selection display
        self.clear_selection()
        
        # Ensure coordinates are in correct order
        left = int(min(x1, x2))
        top = int(min(y1, y2))
        right = int(max(x1, x2))
        bottom = int(max(y1, y2))
        
        # Only show selection if there's a meaningful area
        if right - left > 5 and bottom - top > 5:
            # Crop the original (bright) image for the selection area
            try:
                selection_crop = self.image.crop((left, top, right, bottom))
                selection_tk = ImageTk.PhotoImage(selection_crop)
                
                # Display the bright selection area
                self.selection_image = self.canvas.create_image(
                    left, top, anchor=tk.NW, image=selection_tk
                )
                
                # Keep a reference to prevent garbage collection
                self.canvas.selection_tk = selection_tk
                
                # Add white border around selection
                self.selection_border = self.canvas.create_rectangle(
                    left, top, right, bottom,
                    outline='white', width=2, fill=''
                )
            except Exception:
                pass  # Ignore errors for invalid crop areas

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
                if os.path.exists(self.screenshot_path):
                    os.remove(self.screenshot_path)
        self.root.destroy()

    def exit(self, event=None):
        if os.path.exists(self.screenshot_path):
            os.remove(self.screenshot_path)
        self.root.destroy()


if __name__ == "__main__":
    check_dependencies()
    main_root = tk.Tk()
    app = SnippingTool(main_root)
    main_root.mainloop()