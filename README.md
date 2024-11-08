## Content
+ [Project Description](#project-description)
+ [Code Help](#help-for-the-code)
    + [Basler Camera](#basler-camera)
    + [Annotation tools](#annotation-tool)
    + [Connecting Google Colab to Google Drive](#connecting-google-colab-to-google-drive)
    + [fine tune YOLO11n-pose](#fine-tune-yolo11n-pose)
    + [Save the best mdoel during the train](#saving-the-best-model-during-the-train)
    + [Save the train result on Google Drive](#save-the-result-on-google-drive)
    + [Test the mdoel on new images](#predict-new-images)


### Project Description
---

#### Key point detection 
A model is trained to give 3 key points on bottles:
+ one point on the cap corner for detecting the color of the bottle
+ one point under the cap for picking coordinates, fir the bottle to be picked by robot
+ one point at the end of the bottle for calculatign the orientation of the bottle

This model was trained on 300 images (no augmented images)
For the annotation, CVAT was utilized. 

<br><br><br><br>

### Code Help
---

### Basler Camera

> Basler camera cannot be opened using `OpenCV`, either its software (`pylon Viwer`) can be used or the following code. A better version of the code can be found [here](./realtime_test/basler_cam.py)

```py
from pypylon import pylon
import cv2
import numpy as np

# Create an instant camera object with the first camera device found
camera = pylon.InstantCamera(pylon.TlFactory.GetInstance().CreateFirstDevice())

# Start grabbing continuously (camera will start to capture images)
camera.StartGrabbing(pylon.GrabStrategy_LatestImageOnly)

# Convert images to OpenCV format and display
converter = pylon.ImageFormatConverter()
# Convert to OpenCV BGR format
converter.OutputPixelFormat = pylon.PixelType_BGR8packed
converter.OutputBitAlignment = pylon.OutputBitAlignment_MsbAligned

while camera.IsGrabbing():
    grabResult = camera.RetrieveResult(5000, pylon.TimeoutHandling_ThrowException)
    if grabResult.GrabSucceeded():
        # Access the image data as a NumPy array
        image = converter.Convert(grabResult)
        img = image.GetArray()
        image_h, image_w, _ = img.shape
        img = cv2.resize(img, (image_w//4, image_h//4))

        cv2.imshow('resized Camera', img)

        # Break loop if 'ESC' is pressed
        if cv2.waitKey(1) & 0xFF == 27:
            break
    
    grabResult.Release()
# Stop camera capturing
camera.StopGrabbing()
cv2.destroyAllWindows()

```

### Annotation tool

[online - CVAT.ai](https://www.cvat.ai/)

> Save the annotated data in `.xml` file.
> + This data will be one line contaning all images data. 
>
> Then it is needed to be converted to `coco` format to be used for YOLO.
> [Convert xml to coco](/keypoint_detection/bottle_neck_keypoint/annotations/cvat_to_coco.py)
 
on-device ***labelme*** : 
```shell
$ pip install labelme
$ labelme
```

### connecting Google Colab to Google Drive

```shell
from google.colab import drive

drive.mount('/content/gdrive')
```

### fine tune YOLO11n-pose

- only one class is accepted in YOLO-pose, so far.
- the label file should be `.txt` and contains one line : `0 bx by bw bh x y` where `0` is the classs ID `bx by` are center point coordinates of the bounding box around the object, `bw bh` are bounding box width and height, `x y` are the position of the key point. If you have more than one key point, all their `x y` should be appended to this line.

### Saving the best model during the train

> you need to turn the flag `save` to true in this line:

```py
model.train(data='/content/gdrive/My Drive/university_west_bottle_pickPoint/config.yaml', epochs=100, imgsz=(640, 480), save=True)

```

### Save the result on Google Drive

```shell
!scp -r /content/runs '/content/gdrive/My Drive/university_west_bottle_pickPoint'

```

### predict new images

```py
from ultralytics import YOLO
import numpy as np
import os

currect_dir = os.path.dirname(__file__)
model_path = currect_dir + '/best.pt'
test_image_path = currect_dir + '/test_images/4_yellow.jpg_0_85.jpg'

model = YOLO(model_path)
results = model(test_image_path)[0]

for result in results:
    for key_point in result.keypoints:
        print(key_point)
```

> The result of this code is this:
```shell
image 1/1 e:\SHiTU\programming\university_west_programming\integerating_sysetems_Vision\keypoint_detection\yolo\test_images\4_yellow.jpg_0_85.jpg: 544x640 1 pick_point, 150.0ms
Speed: 5.0ms preprocess, 150.0ms inference, 2.0ms postprocess per image at shape (1, 3, 544, 640)
ultralytics.engine.results.Keypoints object with attributes:      

conf: None
data: tensor([[[449.8272, 169.6225],
         [441.8085, 191.5298],
         [339.0192, 285.0518]]])
has_visible: False
orig_shape: (512, 612)
shape: torch.Size([1, 3, 2])
xy: tensor([[[449.8272, 169.6225],
         [441.8085, 191.5298],
         [339.0192, 285.0518]]])
xyn: tensor([[[0.7350, 0.3313],
         [0.7219, 0.3741],
         [0.5540, 0.5567]]])
```

> For getting only xy coordinates, make this change in the for loop:

```py
result.keypoints.xy.tolist()
```