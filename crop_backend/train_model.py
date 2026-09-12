import tensorflow as tf
from tensorflow.keras import layers, models
from tensorflow.keras.applications import EfficientNetB0
from tensorflow.keras.callbacks import EarlyStopping, ModelCheckpoint
import os
import json

# ==============================
# DATASET PATH
# ==============================

DATASET_PATH = r"C:\Users\Divyesh Chauhan\OneDrive\Desktop\crop_dataset"

# ==============================
# SETTINGS
# ==============================

IMG_SIZE = (224, 224)
BATCH_SIZE = 16
EPOCHS = 10
SEED = 123

# ==============================
# LOAD TRAINING DATA
# ==============================

train_ds = tf.keras.utils.image_dataset_from_directory(
    DATASET_PATH,
    validation_split=0.2,
    subset="training",
    seed=SEED,
    image_size=IMG_SIZE,
    batch_size=BATCH_SIZE
)

# ==============================
# LOAD VALIDATION DATA
# ==============================

val_ds = tf.keras.utils.image_dataset_from_directory(
    DATASET_PATH,
    validation_split=0.2,
    subset="validation",
    seed=SEED,
    image_size=IMG_SIZE,
    batch_size=BATCH_SIZE
)

# ==============================
# CLASS NAMES
# ==============================

class_names = train_ds.class_names

print("\n==============================")
print("TOTAL CLASSES:", len(class_names))
print("==============================")

for i, name in enumerate(class_names):
    print(i, "=", name)

# ==============================
# SAVE LABELS
# ==============================

AI_MODEL_DIR = os.path.join(
    os.path.dirname(__file__),
    "crop_api",
    "ai_model"
)

os.makedirs(AI_MODEL_DIR, exist_ok=True)

with open(
    os.path.join(AI_MODEL_DIR, "labels.txt"),
    "w",
    encoding="utf-8"
) as f:

    for name in class_names:
        f.write(name + "\n")

# ==============================
# PERFORMANCE
# ==============================

AUTOTUNE = tf.data.AUTOTUNE

train_ds = train_ds.prefetch(AUTOTUNE)
val_ds = val_ds.prefetch(AUTOTUNE)

# ==============================
# DATA AUGMENTATION
# ==============================

data_augmentation = tf.keras.Sequential([
    layers.RandomFlip("horizontal"),
    layers.RandomRotation(0.1),
    layers.RandomZoom(0.1),
])

# ==============================
# BASE MODEL
# ==============================

base_model = EfficientNetB0(
    include_top=False,
    weights="imagenet",
    input_shape=(224, 224, 3)
)

base_model.trainable = False

# ==============================
# BUILD MODEL
# ==============================

inputs = layers.Input(shape=(224, 224, 3))

x = data_augmentation(inputs)

x = base_model(
    x,
    training=False
)

x = layers.GlobalAveragePooling2D()(x)

x = layers.Dropout(0.3)(x)

outputs = layers.Dense(
    len(class_names),
    activation="softmax"
)(x)

model = models.Model(
    inputs,
    outputs
)

# ==============================
# COMPILE
# ==============================

model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
    loss="sparse_categorical_crossentropy",
    metrics=["accuracy"]
)

# ==============================
# MODEL PATH
# ==============================

MODEL_PATH = os.path.join(
    AI_MODEL_DIR,
    "crop_model_33.keras"
)

# ==============================
# CALLBACKS
# ==============================

checkpoint = ModelCheckpoint(
    MODEL_PATH,
    monitor="val_accuracy",
    save_best_only=True,
    verbose=1
)

early_stop = EarlyStopping(
    monitor="val_accuracy",
    patience=3,
    restore_best_weights=True
)

# ==============================
# TRAIN
# ==============================

print("\n==============================")
print("STARTING TRAINING")
print("==============================\n")

history = model.fit(
    train_ds,
    validation_data=val_ds,
    epochs=EPOCHS,
    callbacks=[
        checkpoint,
        early_stop
    ]
)

# ==============================
# SAVE FINAL MODEL
# ==============================

model.save(MODEL_PATH)

print("\n==============================")
print("TRAINING COMPLETE")
print("==============================")

print("Classes:", len(class_names))
print("Model saved at:")
print(MODEL_PATH)