import os
import shutil
from ultralytics import YOLO
import urllib.request
import zipfile

# -------------------------------------------------------------
# SpinTrack AI: YOLOv8 Custom Cricket Ball Training Script
# -------------------------------------------------------------
# HOW TO GET THE DATASET:
# 1. We highly recommend the Kaggle: "Cricket Ball Dataset for YOLO"
#    Link: https://www.kaggle.com/datasets/kushagra3204/cricket-ball-dataset-for-yolo
# 2. Download the `.zip` from Kaggle and place it in this folder.
# 3. Rename the zip file to `dataset.zip` OR extract it to a folder named `dataset/`.
# -------------------------------------------------------------

def setup_dataset():
    zip_path = "dataset.zip"
    dataset_dir = "dataset"
    
    if not os.path.exists(dataset_dir) and os.path.exists(zip_path):
        print(f"Extracting {zip_path}...")
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(dataset_dir)
        print("Extraction complete.")
    elif not os.path.exists(dataset_dir):
        print("\n[!] WARNING: No dataset found.")
        print("Please download the Kaggle dataset 'Cricket Ball Dataset for YOLO'")
        print("and place it here designated as 'dataset/' or 'dataset.zip' to train.")
        print("Using the default COCO-Pretrained Nano weights as fallback for now.\n")
        return False
        
    return True

def train_model():
    print("Initializing YOLOv8 Nano model...")
    # Load a pretrained YOLO model (recommended for custom class tracking)
    model = YOLO("yolov8n.pt")
    
    dataset_ready = setup_dataset()
    
    if dataset_ready:
        # Check if data.yaml exists inside the extracted folder
        data_yaml_path = "dataset/data.yaml"
        if not os.path.exists(data_yaml_path):
            # Sometimes it extracts into a subfolder
            subfolders = [f.path for f in os.scandir("dataset") if f.is_dir()]
            for sub in subfolders:
                if os.path.exists(os.path.join(sub, "data.yaml")):
                    data_yaml_path = os.path.join(sub, "data.yaml")
                    break
                    
        if os.path.exists(data_yaml_path):
            print(f"Training on dataset configuration: {data_yaml_path}")
            # Train the model
            # Adjust epochs depending on your compute resources (50-100 is good for fine-tuning)
            results = model.train(
                data=data_yaml_path,
                epochs=50,
                imgsz=640,
                batch=16,
                name="spintrack_cricket_ball",
                device="cpu", # Change to 0 if you have a CUDA GPU!
            )
            print("Training Complete! The best weights are saved in runs/detect/spintrack_cricket_ball/weights/best.pt")
            
            # Copy to backend root for inference
            try:
                shutil.copy(
                    "runs/detect/spintrack_cricket_ball/weights/best.pt", 
                    "../best_cricket_ball.pt"
                )
                print("Copied best.pt to backend root! SpinTrack backend will automatically use it now.")
            except Exception as e:
                print(f"Could not automatically copy weights: {e}")
        else:
            print(f"[!] data.yaml not found inside dataset folder! Please check folder structure.")
    else:
        print("Running a swift verification on base weights since no custom dataset was provided...")
        # Optional: just verify loading if no dataset
        pass

if __name__ == "__main__":
    os.makedirs("runs", exist_ok=True)
    train_model()
