import tensorflow as tf
import numpy as np

from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing import image

# Model Load
model = load_model("crop_api/ai_model/crop_model.keras")

# Labels Load
with open("crop_api/ai_model/labels.txt") as f:
    class_names = [line.strip() for line in f]

# Test Image
IMAGE_PATH = "test.jpg"

img = image.load_img(
    IMAGE_PATH,
    target_size=(224,224)
)

img_array = image.img_to_array(img)

img_array = np.expand_dims(img_array, axis=0)

img_array = tf.keras.applications.efficientnet.preprocess_input(
    img_array
)

prediction = model.predict(img_array)

index = np.argmax(prediction)

confidence = np.max(prediction)*100

print()

print("Prediction :", class_names[index])

print("Confidence :", confidence)

print()

print(prediction)