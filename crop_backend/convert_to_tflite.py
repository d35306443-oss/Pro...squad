import tensorflow as tf

print("=" * 50)
print("Loading Keras Model...")
print("=" * 50)

model = tf.keras.models.load_model(
    "crop_api/ai_model/crop_model.keras"
)

print("Model Loaded Successfully")

print("=" * 50)
print("Converting to TFLite...")
print("=" * 50)

converter = tf.lite.TFLiteConverter.from_keras_model(model)

# Keep float32 model
converter.optimizations = []

converter.target_spec.supported_ops = [
    tf.lite.OpsSet.TFLITE_BUILTINS
]

converter.inference_input_type = tf.float32
converter.inference_output_type = tf.float32

tflite_model = converter.convert()

output_path = "crop_api/ai_model/crop_model.tflite"

with open(output_path, "wb") as f:
    f.write(tflite_model)

print("=" * 50)
print("SUCCESS")
print("Saved :", output_path)
print("=" * 50)