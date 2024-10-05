import librosa
import numpy as np
import tensorflow as tf  # For loading the model

# Function to classify an audio file using the trained model
def extract_mfcc(audio, sr, n_mfcc=40):
    mfcc = librosa.feature.mfcc(y=audio, sr=sr, n_mfcc=n_mfcc)  # Extract MFCC features
    mfcc = np.mean(mfcc.T, axis=0)  # Average MFCCs over time to get a single vector
    return mfcc

def classify_audio(file_path, model_path):
    try:
        # Load the audio file
        y, sr = librosa.load(file_path, sr=16000)  # Adjust sample rate if needed
        
        # Extract MFCC features from the audio data
        mfcc_features = extract_mfcc(y, sr)
        
        # Check the shape of extracted features
        print(f"Extracted MFCC shape: {mfcc_features.shape}")
        
        # Load the trained model
        model = tf.keras.models.load_model(model_path)
        
        # Reshape the features for model input
        # Reshape to (1, 40, 1, 1) to match the model's expected input
        mfcc_features = mfcc_features.reshape(1, 40, 1, 1)
        
        # Check the reshaped input shape
        print(f"Reshaped MFCC shape: {mfcc_features.shape}")
        
        # Make a prediction
        prediction = model.predict(mfcc_features)
        
        # Print prediction values for debugging
        print(f"Prediction: {prediction}")
        
        # Interpret the prediction (assuming binary classification)
        return 'danger' if prediction[0][0] > 0.5 else 'safe'
    
    except Exception as e:
        print(f"Error processing audio file: {e}")
        return "Error"

# Example usage
new_audio_file = 'Recording (28).wav'
model_path = 'mainmodel.h5'
result = classify_audio(new_audio_file, model_path)
print(f'The audio indicates: {result}')
