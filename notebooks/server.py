from flask import Flask, request, jsonify
import os
import uuid
import librosa
import numpy as np
import tensorflow as tf
import wave
import speech_recognition as sr
from pydub import AudioSegment
import torch
from transformers import DistilBertTokenizer, DistilBertForSequenceClassification

app = Flask(__name__)

# Paths to the trained models
MODEL_PATH = 'mainmodel.h5'  # Audio classification model
TEXT_MODEL_PATH = 'best_model_accuracy_final.pth'  # Text classification model

# Load the audio classification model
audio_model = tf.keras.models.load_model(MODEL_PATH)

# Load the text classification model
device = 'cpu'
text_model = DistilBertForSequenceClassification.from_pretrained(
    'distilbert-base-multilingual-cased',
    num_labels=1
)
text_model.load_state_dict(torch.load(TEXT_MODEL_PATH))  
text_model.to(device)

# Load the tokenizer for text classification
tokenizer = DistilBertTokenizer.from_pretrained('distilbert-base-multilingual-cased')

# Function to extract MFCC features
def extract_mfcc(audio, sr, n_mfcc=40):
    mfcc = librosa.feature.mfcc(y=audio, sr=sr, n_mfcc=n_mfcc)
    mfcc = np.mean(mfcc.T, axis=0)
    return mfcc

# Function to classify audio using the loaded model
def classify_audio(file_path):
    try:
        y, sr = librosa.load(file_path, sr=16000)
        mfcc_features = extract_mfcc(y, sr)
        mfcc_features = mfcc_features.reshape(1, 40, 1, 1)
        prediction = audio_model.predict(mfcc_features)
        return 'danger' if prediction[0][0] < 0.5 else 'safe'
    except Exception as e:
        print(f"Error processing audio file: {e}")
        return "Error"

# Function to validate WAV format
def convert_to_valid_wav(file_path, output_path):
    """
    Check if the WAV file has a valid RIFF header.
    If not, convert it to a valid WAV format.
    """
    try:
        # Try opening the file as a WAV file with a valid RIFF header
        with wave.open(file_path, 'rb') as wav_file:
            # If the file opens without errors, it's valid
            print(f"{file_path} is a valid WAV file with a RIFF header.")
            return file_path  # No conversion needed
    except wave.Error:
        # If it raises a wave.Error, the RIFF header is missing or invalid
        print(f"{file_path} does not have a valid RIFF header. Converting...")

        # Convert the file to valid WAV format using pydub
        audio = AudioSegment.from_file(file_path)
        audio.export(output_path, format="wav")
        print(f"File converted to valid WAV format: {output_path}")
        return output_path

# Function to transcribe audio
def transcribe_audio(file_path):
    r = sr.Recognizer()
    
    # Define the output path for the converted WAV file
    converted_file_path = file_path.replace(".wav", "_converted.wav")
    
    # Convert if necessary, ensuring the file has a valid RIFF header
    valid_wav_path = convert_to_valid_wav(file_path, converted_file_path)

    # Load the valid audio file
    with sr.AudioFile(valid_wav_path) as source:
        print(f"Processing file: {valid_wav_path}")
        audio_txt = r.record(source)
    
    # Try to recognize the speech
    try:
        text = r.recognize_google(audio_txt)
        print(f"Transcribed Text: {text}\n")
        return text
    except sr.UnknownValueError:
        print(f"Could not understand audio from {valid_wav_path}.")
        return None
    except sr.RequestError as e:
        print(f"Could not request results from Google Speech Recognition service for {valid_wav_path}; {e}")
        return None

# Function to predict using text classification model
def predict_custom_data(model, input_ids, attention_mask):
    model.eval()
    with torch.no_grad():
        outputs = model(input_ids, attention_mask=attention_mask)
        preds = torch.sigmoid(outputs.logits.squeeze(1))
        preds = (preds > 0.5).float()
    return preds.cpu().numpy()

# API endpoint to receive and process audio
@app.route('/process_audio', methods=['POST'])
def process_audio():
    if 'audio' not in request.files:
        return jsonify({"error": "No audio file in request"}), 400

    audio = request.files['audio']
    
    # Generate a unique filename
    unique_filename = f"{uuid.uuid4()}.wav"
    file_path = os.path.join('received_audio', unique_filename)
    os.makedirs(os.path.dirname(file_path), exist_ok=True)
    audio.save(file_path)

    print(f"Audio saved as {file_path}")

    # Classify the audio
    classification_result = classify_audio(file_path)
    print(f"Audio classification result: {classification_result}")

    if classification_result == 'danger':
        return jsonify({
            "message": "Audio processed successfully",
            "classification": "danger"
        }), 200
    
    # Convert audio to text
    transcribed_text = transcribe_audio(file_path)
    if transcribed_text is None:
        return jsonify({"error": "Could not transcribe audio"}), 500

    print(f"Transcribed Text: {transcribed_text}")

    # Classify the transcribed text
    encoded_inputs = tokenizer(
        [transcribed_text],
        truncation=True,
        padding=True,
        max_length=128,
        return_tensors='pt'
    )

    input_ids = encoded_inputs['input_ids'].to(device)
    attention_mask = encoded_inputs['attention_mask'].to(device)

    predictions = predict_custom_data(text_model, input_ids, attention_mask)

    # Determine final classification based on text analysis
    final_classification = 'danger' if predictions[0] == 1 else 'safe'
    print(final_classification)
    return jsonify({
        "message": "Audio processed successfully",
        "classification": final_classification
    }), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
