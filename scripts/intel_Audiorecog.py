import speech_recognition as sr
from pydub import AudioSegment
import wave

def convert_to_valid_wav(file_path, output_path):
    """
    We have to Check if the WAV file has a valid RIFF header.
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
    except sr.UnknownValueError:
        print(f"Could not understand audio from {valid_wav_path}.")
    except sr.RequestError as e:
        print(f"Could not request results from Google Speech Recognition service for {valid_wav_path}; {e}")

# Example usage
file_path = 'received_audio/2962f17a-2dd2-499c-b0d9-8c76246adb8a.wav'
transcribe_audio(file_path)
