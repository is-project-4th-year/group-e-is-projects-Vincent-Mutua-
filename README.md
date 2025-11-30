# ZenMind: AI-Driven Cognitive and Emotional Support System

## Project Overview
ZenMind is a unified mobile application designed to assist adults with Attention-Deficit/Hyperactivity Disorder (ADHD) in managing executive dysfunction and emotional dysregulation. Current digital health interventions often operate in silos, separating productivity tools from therapeutic support. This fragmentation forces users to switch contexts during periods of stress, frequently leading to tool abandonment.

This project bridges that gap by integrating cognitive scaffolding tools (task decomposition and focus timers) with an empathetic conversational agent. The system leverages a hybrid Artificial Intelligence architecture to provide real-time emotional validation alongside practical task management, thereby reducing the friction associated with task initiation.

## Key Features

### 1. Empathetic Conversational Agent
The core of the system is a Retrieval-Augmented Generation (RAG) chatbot that functions as a proactive support companion.
* **Hybrid Intelligence:** Utilizes a fine-tuned DistilBERT model ("Empathy Sensor") to detect 27 granular emotional states and a Gemini Large Language Model for response generation.
* **Contextual Grounding:** Responses are informed by a vector database of clinical counseling transcripts and ADHD-specific literature, ensuring therapeutic validity.
* **Safety Guardrails:** Includes heuristic crisis detection to identify high-risk inputs and strictly formatted system prompts to prevent hallucination.

### 2. Intelligent Task Management
* **Automated Decomposition:** Users can input complex or overwhelming goals. The system utilizes generative AI to break these goals down into actionable, low-friction micro-steps with estimated durations.
* **Focus Session Integration:** Tasks are directly linked to a visual timer based on the Pomodoro technique to scaffold sustained attention.

### 3. Contextual Journaling
* **Multi-Modal Input:** Supports text, speech-to-text, and image attachments to minimize the cognitive load of reflection.
* **Secure Persistence:** Entries are stored in a secure cloud environment, allowing the user to track emotional patterns over time.

## System Architecture

The project employs a hybrid client-server-inference architecture:

* **Client Layer:** A cross-platform mobile application developed using the Flutter framework.
* **Orchestration Layer:** Google Firebase serves as the Backend-as-a-Service (BaaS), handling authentication, real-time database synchronization (Cloud Firestore), and media storage.
* **Inference Layer:** A dedicated Python backend hosts the heavy machine learning workloads. This component runs within a Google Colab runtime (leveraging T4 GPU resources) and is exposed via a FastAPI interface tunneled through Ngrok.

## Technology Stack

### Frontend
* **Framework:** Flutter (Dart)
* **Version:** 3.29.3
* **State Management:** Provider / Riverpod
* **Compatibility:** Android 13+ / iOS 16+

### Backend & Infrastructure
* **Authentication:** Firebase Authentication
* **Database:** Cloud Firestore (NoSQL)
* **Storage:** Firebase Cloud Storage
* **Server Logic:** Google Cloud Functions

### AI & Machine Learning
* **Language:** Python 3.10+
* **Frameworks:** PyTorch 2.4, Hugging Face Transformers 4.57.2
* **Orchestration:** LangChain, ChromaDB
* **Models:**
    * *Classification:* DistilBERT (Fine-tuned on GoEmotions)
    * *Generation:* Google Gemini 1.5 Pro/Flash
    * *Embeddings:* all-MiniLM-L6-v2
* **API Middleware:** FastAPI, Uvicorn, Ngrok

## Installation and Setup

### Prerequisites
* Flutter SDK installed and configured.
* Android Studio or VS Code.
* Google Cloud Project with Firebase enabled.
* Google Colab account for running the inference engine.

### 1. Frontend Setup
1.  Clone the repository.
2.  Navigate to the application directory:
    ```bash
    cd zenmind_app
    ```
3.  Install dependencies:
    ```bash
    flutter pub get
    ```
4.  Configure Firebase:
    * Place the `google-services.json` file in `android/app/`.
    * Place the `GoogleService-Info.plist` file in `ios/Runner/`.
5.  Launch the application:
    ```bash
    flutter run
    ```

### 2. Backend Inference Setup
1.  Open the provided Jupyter Notebook (`ZenMind_Inference_Backend.ipynb`) in Google Colab.
2.  Set the necessary environment secrets in Colab:
    * `GOOGLE_API_KEY` (for Gemini)
    * `NGROK_TOKEN` (for tunneling)
3.  Execute all cells sequentially to:
    * Install Python dependencies.
    * Load and fine-tune the DistilBERT model.
    * Build the RAG Vector Store.
    * Start the FastAPI server.
4.  Copy the public Ngrok URL generated in the final cell output and update the base API URL in the Flutter application configuration.

## License
This project is submitted in partial fulfillment of the requirements for the Degree in Bachelor of Science in Informatics and Computer Science at Strathmore University.

**Developer:** Mutua Vincent Mumo
**Supervisor:** Ms. Eunice Manyasi
