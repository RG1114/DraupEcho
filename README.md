# <bold>DraupECHO</bold><br>
## <bold>Project Overview</bold><br>
DraupECHO is an innovative system designed to detect dangerous situations through real-time audio analysis. The system employs a multi-step approach that combines:

1. <b>Audio Tone Analysis:</b> Using machine learning models to analyze the tone of the speaker's voice to determine if the person is in a distressful or dangerous situation.
2. <b>Speech-to-Text Conversion:</b> The audio is converted into text for further analysis.
3. <b>Text Sentiment Analysis:</b> A sentiment analysis model is used to examine the text and detect whether it reflects a dangerous or safe situation based on the content of the speech.

# Key Features
<li><b>Real-time Audio Tone Analysis:</b> Classifies the audio based on MFCC features to detect danger from the tone of the voice.</li>
<li><b>Speech-to-Text Conversion:</b> Transforms audio into text using speech recognition libraries for further processing.</li>
<li><b>Sentiment Analysis on Text:</b> Analyzes the sentiment of the text to further detect danger.</li>
<li><b>Comprehensive Danger Detection:</b> Combines both tone and textual analysis for more accurate danger detection.</li>
<li><b>Emergency SMS Alerts:</b> Sends automated SMS notifications to designated contacts upon detecting potential danger, ensuring timely response.</li>
<li><b>Location Tracking:</b> Captures and sends the user’s location along with the SMS alert, providing emergency contacts with crucial information.</li>

# Project Structure
- **models/**: Contains model files for audio analysis and sentiment analysis. [View models](./models)
- **notebooks/**: Contains notebooks for audio analysis and text analysis. [View notebooks](./notebooks)
- **scripts/**: Contains scripts for audio classification,speech to text conversion and text classification. [View scripts](./scripts)


# Dependencies
<li>TensorFlow</li>
<li>Librosa</li>
<li>Soundfile</li>
<li>Twilio API (for SMS notifications)</li>
<li>Geolocation API</li>

![Alt text](app.jpg)


