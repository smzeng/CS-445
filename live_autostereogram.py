# Live autostereogram program
# CS 445 Final Project
# Michael Korenchan, Stacy Zeng, Surya Bandyopadhyay

import arcade
from arcade.experimental import Shadertoy
import cv2


# define live stereogram class for arcade rendering
class LiveStereogram(arcade.Window):

    def __init__(self):
        # initialize with parent constructor
        window_size = (1280, 720)
        super().__init__(width=window_size[0], height=window_size[1])


        # load glsl shader file and initialize renderer object
        file_name = "live_stereogram.glsl"
        self.shader_renderer = Shadertoy(size=self.get_size(), main_source=open(file_name).read())

        # load texture for tiling
        self.texture = arcade.load_texture("./images/texture.jpg")
        # create FBO for sampling and initialize it with texture data
        self.channel0 = self.shader_renderer.ctx.framebuffer(
            color_attachments=[self.shader_renderer.ctx.texture(self.texture.size, components=4, data=self.texture.image.tobytes())]
        )
        # initialize sampler
        self.shader_renderer.channel_0 = self.channel0.color_attachments[0]

        # set up video capture stuff
        self.vid_cap = cv2.VideoCapture(0)
        self.face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
        if not self.vid_cap.isOpened():
            print("Cannot open camera")
            exit()
        self.last_x = 0  # for unreliable face detection

    
    # function to get a horizontal position of a detected face
    def get_face_pos(self):
        # read frame
        ret_val, frame = self.vid_cap.read()
        if not ret_val:
            print("Unable to read frame from camera")
            return self.last_x
        # convert to grayscale and detect faces
        faces = self.face_cascade.detectMultiScale(cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY))
        for (x, y, w, h) in faces:
            # if there are any faces at all, just return the first value
            x -= frame.shape[1] / 2.5
            self.last_x = x
            return self.last_x
        return self.last_x


    def on_draw(self):
        # get face location
        face_x = self.get_face_pos()
        # send face location as uniform to the shader
        self.shader_renderer.program['face_pos'] = face_x, self.mouse["x"]
        # draw
        self.shader_renderer.render()

if __name__ == "__main__":
    # run program
    LiveStereogram()
    arcade.run()