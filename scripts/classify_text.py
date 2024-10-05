import pandas as pd
import torch
from transformers import DistilBertTokenizer, DistilBertForSequenceClassification, AdamW
from transformers import get_linear_schedule_with_warmup
from tqdm import tqdm

# Load pre-trained BERT model
device = 'cpu'
model = DistilBertForSequenceClassification.from_pretrained(
    'distilbert-base-multilingual-cased',
    num_labels=1
)
model.load_state_dict(torch.load('best_model_accuracy_final.pth'))  
model.to(device)  

def predict_custom_data(model, input_ids, attention_mask, device):
    model.eval()  # Set model to evaluation mode

    with torch.no_grad():  # Disable gradient calculation for inference
        outputs = model(input_ids, attention_mask=attention_mask)
        preds = torch.sigmoid(outputs.logits.squeeze(1))  # Apply sigmoid to get probabilities
        preds = (preds > 0.5).float()  # Convert probabilities to binary (0 or 1)

    return preds.cpu().numpy()  # Return predictions as a numpy array

# Load the tokenizer
tokenizer = DistilBertTokenizer.from_pretrained('distilbert-base-multilingual-cased')

custom_texts = ["please dont hurt me"] 

max_length = 128  # 

encoded_inputs = tokenizer(
    custom_texts,
    truncation=True,
    padding=True,
    max_length=max_length,
    return_tensors='pt'  
)

input_ids = encoded_inputs['input_ids']
attention_mask = encoded_inputs['attention_mask']

input_ids = input_ids.to(device)
attention_mask = attention_mask.to(device)

predictions = predict_custom_data(model, input_ids, attention_mask, device)

for i, text in enumerate(custom_texts):
    print(f"Text: {text} -> Prediction: {'Dangerous' if predictions[i] == 1 else 'Safe'}")
