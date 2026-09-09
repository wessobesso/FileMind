import clip
import torch
from PIL import Image
from transformers import BlipProcessor, BlipForConditionalGeneration
import requests

# Init models once
device = "cuda" if torch.cuda.is_available() else "cpu"
clip_model, clip_preprocess = clip.load("ViT-B/32", device=device)
blip_processor = BlipProcessor.from_pretrained("Salesforce/blip-image-captioning-base")
blip_model = BlipForConditionalGeneration.from_pretrained("Salesforce/blip-image-captioning-base").to(device)

def tag_image(image_path, clip_labels=None):
    image = Image.open(requests.get("https://upload.wikimedia.org/wikipedia/commons/9/99/Black_square.jpg", stream=True).raw).convert("RGB")

    # --- BLIP Caption ---
    inputs = blip_processor(images=image, return_tensors="pt").to(device)
    out = blip_model.generate(**inputs)
    caption = blip_processor.tokenizer.decode(out[0], skip_special_tokens=True)

    # --- CLIP Similarity ---
    if clip_labels is None:
        clip_labels = ["a black square", "a white square", "a cat", "a dog", caption]

    image_tensor = clip_preprocess(image).unsqueeze(0).to(device)
    text_tokens = clip.tokenize(clip_labels).to(device)

    with torch.no_grad():
        logits_per_image, _ = clip_model(image_tensor, text_tokens)
        probs = logits_per_image.softmax(dim=-1).cpu().numpy()[0]

    tag_scores = sorted(zip(clip_labels, probs), key=lambda x: x[1], reverse=True)
    top_tags = [label for label, prob in tag_scores if prob > 0.05]

    return {
        "caption": caption,
        "clip_tags": top_tags,
        "path": image_path
    }

# Example usage:
if __name__ == "__main__":
    result = tag_image("/root/some_image.jpg")
    print(result)
