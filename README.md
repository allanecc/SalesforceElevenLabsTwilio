# Salesforce + ElevenLabs & Twilio Outbound Voice AI

A Salesforce integration that enables automated, AI-driven outbound phone calls directly from CRM records using **Salesforce Screen Flows**, **External Services**, **ElevenLabs Conversational AI**, and **Twilio**. 

This project also includes a public **Apex REST Webhook** to automatically record call transcriptions, summaries, and metadata as completed **Tasks** linked to the corresponding Contact in Salesforce.

---

## 🌟 Features

* **One-Click AI Calls:** Initiated via a custom Screen Flow embedded on Salesforce Contact / Lead Lightning pages.
* **OpenAPI 3.0 Integration:** Leverages Salesforce External Services and Named Credentials to connect seamlessly with ElevenLabs APIs.
* **Contextual AI Conversations:** Dynamic variables (`First Name`, `Ticket ID`, etc.) passed to the ElevenLabs agent prompt at the start of the call.
* **Automated Post-Call Processing:** Exposes an Apex REST endpoint (`without sharing`) on Experience Cloud to capture call details upon completion.
* **Automatic CRM Logging:** Creates a `Task` record with structured transcriptions, AI call outcome summaries, and automatically links to the Contact based on phone matching.

---

## 🏗️ Architecture & Flow

1. **Trigger:** User launches the Screen Flow from a Contact record page in Salesforce.
2. **Callout:** Salesforce calls ElevenLabs Twilio Outbound API via External Services (`POST /v1/convai/twilio/outbound-call`).
3. **Execution:** ElevenLabs connects with Twilio to dial the recipient and manages the conversational voice session.
4. **Post-Call Webhook:** Upon call completion, ElevenLabs posts a JSON payload containing the transcript, summary, and call details to the Salesforce Apex REST endpoint.
5. **Record Creation:** Salesforce processes the payload and logs a completed `Task` under the Contact record.

---

## 📁 Repository Structure

```
├── force-app/
│   └── main/
│       └── default/
│           ├── classes/
│           │   ├── ElevenLabsWebhookResource.cls
│           │   └── ElevenLabsWebhookResourceTest.cls
│           ├── flows/
│           │   └── Launch_ElevenLabs_Call.flow-meta.xml
│           └── externalServices/
│               └── ElevenLabs_Twilio_Outbound_API.externalService-meta.xml
├── openapi/
│   └── elevenlabs-twilio-spec.json
└── README.md
```

---

## ⚙️ Setup & Configuration

### 1. ElevenLabs & Twilio Setup
1. Create a Conversational AI agent in [ElevenLabs](https://elevenlabs.io).
2. Connect your **Twilio** account credentials inside the ElevenLabs Workspace settings.
3. Import or register a phone number in ElevenLabs (`agent_phone_number_id`).

### 2. Salesforce Credentials & External Services
1. **External Credential:** Create `ElevenLabs_External` using Custom Headers:
   * **Header Name:** `xi-api-key`
   * **Header Value:** `{!$Credential.Parameter.api_key}`
2. **Named Credential:** Create `ElevenLabs_API` pointing to `https://api.elevenlabs.io`.
3. **External Services:** Import the OpenAPI 3.0 specification (`openapi/elevenlabs-twilio-spec.json`).

### 3. Screen Flow Setup
1. Create a Screen Flow with an input variable `recordId`.
2. Fetch Contact details (`Get Records`).
3. Populate `ExternalService__..._TwilioCallPayload` variables (`agent_id`, `agent_phone_number_id`, `to_number`).
4. Execute the External Service Action (`makeTwilioCall`).
5. Embed the Flow on the Contact Lightning Page layout.

### 4. Post-Call Webhook Endpoint
1. Deploy `ElevenLabsWebhookResource.cls` to your org.
2. Expose the Apex REST class on a public **Salesforce Experience Cloud (Site)** Guest User Profile.
3. Configure the Webhook URL in ElevenLabs Agent Settings:
   ```text
   https://<your-domain>.my.site.com/services/apexrest/elevenlabs/webhook/v1
   ```

---

## 🧪 Testing

1. Navigate to any Contact record with a valid E.164 mobile number.
2. Launch the **Lanzar Llamada ElevenLabs** flow.
3. Complete the voice conversation with the AI agent.
4. Check the **Activity History** under the Contact record to view the logged `Task` with summary and full transcript.

---

## 🛠️ Tech Stack

* **CRM:** Salesforce (Apex REST, Screen Flows, External Services, Named Credentials)
* **Voice AI:** ElevenLabs Conversational AI
* **Telephony Provider:** Twilio
* **API Spec:** OpenAPI 3.0 / JSON
