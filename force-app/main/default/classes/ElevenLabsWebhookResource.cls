@RestResource(urlMapping='/elevenlabs/webhook/v1/*')
global without sharing class ElevenLabsWebhookResource {

    @HttpPost
    global static void handleIncomingWebhook() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        try {
            String requestBody = req.requestBody.toString();
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
            
            String conversationId = (String) payload.get('conversation_id');
            
            // 1. Extraer resumen y análisis
            String summary = '';
            String callSuccessStatus = 'Unassigned';
            if (payload.containsKey('analysis') && payload.get('analysis') != null) {
                Map<String, Object> analysis = (Map<String, Object>) payload.get('analysis');
                summary = (String) analysis.get('transcript_summary');
                if (analysis.containsKey('call_successful')) {
                    callSuccessStatus = String.valueOf(analysis.get('call_successful'));
                }
            }
            
            // 2. Extraer número de teléfono (metadata -> phone_call_provider_details -> twilio)
            String toNumber = '';
            String callSid = '';
            if (payload.containsKey('metadata') && payload.get('metadata') != null) {
                Map<String, Object> metadata = (Map<String, Object>) payload.get('metadata');
                if (metadata.containsKey('phone_call_provider_details') && metadata.get('phone_call_provider_details') != null) {
                    Map<String, Object> providerDetails = (Map<String, Object>) metadata.get('phone_call_provider_details');
                    if (providerDetails.containsKey('twilio') && providerDetails.get('twilio') != null) {
                        Map<String, Object> twilioDetails = (Map<String, Object>) providerDetails.get('twilio');
                        toNumber = (String) twilioDetails.get('to_number');
                        callSid = (String) twilioDetails.get('call_sid');
                    }
                }
            }
            
            // 3. Formatear la transcripción
            String formattedTranscript = '';
            if (payload.containsKey('transcript') && payload.get('transcript') != null) {
                List<Object> transcriptList = (List<Object>) payload.get('transcript');
                for (Object item : transcriptList) {
                    Map<String, Object> turn = (Map<String, Object>) item;
                    String role = (String) turn.get('role');
                    String message = (String) turn.get('message');
                    formattedTranscript += (role != null ? role.toUpperCase() : 'UNKNOWN') + ': ' + message + '\n';
                }
            }

            // 4. Buscar el contacto en Salesforce por número de teléfono
            Id contactId = null;
            if (String.isNotBlank(toNumber)) {
                // Eliminar prefijo '+' si fuera necesario en la búsqueda de tu Org
                List<Contact> contacts = [
                    SELECT Id 
                    FROM Contact 
                    WHERE MobilePhone = :toNumber OR Phone = :toNumber 
                    LIMIT 1
                ];
                if (!contacts.isEmpty()) {
                    contactId = contacts[0].Id;
                }
            }

            // 5. Crear el registro de Task en Salesforce
            Task callTask = new Task();
            callTask.Subject = 'Llamada con IA (ElevenLabs) - Status: ' + callSuccessStatus;
            callTask.Status = 'Completed';
            callTask.Priority = 'Normal';
            callTask.TaskSubtype = 'Call';
            
            // Vincular al Contacto si se encontró
            if (contactId != null) {
                callTask.WhoId = contactId;
            }
            
            // Cuerpo descriptivo detallado
            String descriptionBody = '';
            if (String.isNotBlank(summary)) {
                descriptionBody += '--- RESUMEN ---\n' + summary + '\n\n';
            }
            descriptionBody += '--- TRANSCRIPCIÓN DETALLADA ---\n' + formattedTranscript;
            if (String.isNotBlank(callSid)) {
                descriptionBody += '\nTwilio Call SID: ' + callSid;
            }
            
            callTask.Description = descriptionBody;
            
            insert callTask;
            
            res.statusCode = 200;
            res.responseBody = Blob.valueOf('{"status": "success", "taskId": "' + callTask.Id + '"}');
            
        } catch (Exception e) {
            res.statusCode = 500;
            res.responseBody = Blob.valueOf('{"error": "' + e.getMessage() + '"}');
        }
    }
}