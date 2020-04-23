global with sharing abstract class WSBaseSystemInterface implements vlocity_cmt.XOMOrchestrationInterfaces.ISystemInterface, vlocity_cmt.XOMOrchestrationInterfaces.IDeferredUpdater {
    public class WSBaseSystemInterfaceException extends Exception {}

    protected Map<String, Object> ctx = new Map<String, Object>();

    global WSBaseSystemInterface() {

    }

    /**
    * This method is a part of ISystemInterface. It is invoked at the start of the batch
    * @param  url  base URL the batch is started for
    * @param  method method this batch is started for
    */
    global virtual void startBatch(String url, String method){
        // Do nothing
    }

    /**
    * Executes a Callout OrchestrationItem
    * if cache is enabled then orchestration item data is retrieved from cache
    * @param  url  base URL to send the request to
    * @param  method method to send the request to
    * @param  item OrchestrationItem that needs to be executed
    */
    global virtual void executeItem(String url, String method, vlocity_cmt__OrchestrationItem__c item) { 
        vLogger.writeInfo('Enter WSBaseSystemInterface.executeItem');
        try {
            // Login or authenticate 
            if (!login(url, item)) {
                throw new WSBaseSystemInterfaceException('Authentication failed.');
            }

            ctx.put('item', item);

            // Get initial payload from the attributes
            Map<String, Object> dataMap = generateOrderDataMap(item);
            ctx.put('dataMap', dataMap);

            // Generate payload string
            String payload = generatePayload(item, dataMap);

            // Convert the input payload to the webservice request of the method
            Object soapRequest = createWSRequest(method, payload);

            // Execute the given Webservice method
            Object soapResponse = invokeWSMethod(method, soapRequest);

            // Transform the webservice response to the output JSON
            Map<String, Object> output = processWSResponse(method, soapResponse);

            ctx.put('output', output);


        } catch (CalloutException ex) { // Capture recoverable exception and notify OM to retry
            vLogger.write(ex);
            throw new vlocity_cmt.XOMOrchestrationInterfaces.SystemInterfaceRecoverableException ('Callout exception ' + ex + ': trying to retry');
        } catch (Exception ex) {
            vLogger.write(ex);
            throw ex;
        } finally {
            vLogger.writeInfo('Exit WSBaseSystemInterface.executeItem');
        }
    }

    /**
    * This method is called at the end of the batch
    * @param  url  base URL for the batch
    * @param  method method for the batch
    */
    global virtual void endBatch(String url, String method) {
        // Do nothing
    }

    /**
    * update DB,
    * from XOMOrchestrationInterfaces, executed when it safe to do it.
    */
    public void updateDatabase() {
        vLogger.writeInfo('Enter WSBaseSystemInterface.updateDatabase');
        try {
            vlocity_cmt__OrchestrationItem__c item = (vlocity_cmt__OrchestrationItem__c)ctx.get('item');
            Map<String, Object> output = (Map<String, Object>)ctx.get('output');
            
            if (item.vlocity_cmt__ResponseAttrsVlocityDataRaptorBundleId__c != null) {
                vlocity_cmt.DRProcessResult result = vlocity_cmt.DRGlobal.process(output, item.vlocity_cmt__ResponseAttrsVlocityDataRaptorBundleId__c);
                output = (Map<String, Object>)result.toJSON();
            }

            if (item.vlocity_cmt__ResponseItemsVlocityDataRaptorBundleId__c != null) {
                vlocity_cmt.DRProcessResult result = vlocity_cmt.DRGlobal.process(output, item.vlocity_cmt__ResponseItemsVlocityDataRaptorBundleId__c);
                output = (Map<String, Object>)result.toJSON();
            }

            if (item.vlocity_cmt__ResponseVlocityDataRaptorBundleId__c != null) {
                vlocity_cmt.DRProcessResult result = vlocity_cmt.DRGlobal.process(output, item.vlocity_cmt__ResponseVlocityDataRaptorBundleId__c);
                output = (Map<String, Object>)result.toJSON();
            }
        } catch (Exception ex) {
            vLogger.write(ex);
        } finally {
            vLogger.writeInfo('Exit WSBaseSystemInterface.updateDatabase');
        }
    }

    /**
     * This method returns the initial JSON payload from the given OrchestrationItem item
     * @param  url  base URL for the batch
     * @param  method method for the batch
     * @param  item Orchestration Item
     * @return      initial payload 
     */
    public Map<String, Object> generateOrderDataMap(vlocity_cmt__OrchestrationItem__c item) {
        Id orderId = null;
        Id accountId;
        SObject[] itemSObjs;
        if (item.vlocity_cmt__OrderItemId__r.OrderId != null) {
            orderId = item.vlocity_cmt__OrderItemId__r.OrderId;
            OrderItem[] oLIs = [
                SELECT Id, 
                        Order.AccountId, 
                        vlocity_cmt__JSONAttribute__c, 
                        vlocity_cmt__Action__c, 
                        vlocity_cmt__LineNumber__c, 
                        vlocity_cmt__Product2Id__c,
                        vlocity_cmt__Product2Id__r.Name 
                FROM OrderItem
                WHERE OrderId = :orderId
                ORDER BY vlocity_cmt__LineNumber__c
            ];
            accountId = oLIs[0].Order.AccountId;

            OrderItem myOLI = (new Map<Id, OrderItem>(oLIs)).get(item.vlocity_cmt__OrderItemId__r.Id);
            String myRootLineNumber = myOLI.vlocity_cmt__LineNumber__c.subString(0, 4);
            itemSObjs = new List<SObject>();
            for (OrderItem oLI : oLIs) {
                if (oLI.vlocity_cmt__LineNumber__c.startsWith(myRootLineNumber)) {
                    itemSObjs.add(oLI);
                }
            }
        } else if (item.vlocity_cmt__FulfilmentRequestLineId__r.vlocity_cmt__FulfilmentRequestId__c != null) {
            orderId = item.vlocity_cmt__FulfilmentRequestLineId__r.vlocity_cmt__FulfilmentRequestId__c;
            itemSObjs = [
                SELECT Id, 
                        vlocity_cmt__FulfilmentRequestID__r.vlocity_cmt__AccountId__c, 
                        vlocity_cmt__JSONAttribute__c, 
                        vlocity_cmt__Action__c, 
                        vlocity_cmt__LineNumber__c, 
                        vlocity_cmt__Product2Id__c,
                        vlocity_cmt__Product2Id__r.Name 
                FROM vlocity_cmt__FulfilmentRequestLine__c
                WHERE vlocity_cmt__FulfilmentRequestID__c = :orderId
                ORDER BY vlocity_cmt__LineNumber__c
            ];
            accountId = ((vlocity_cmt__FulfilmentRequestLine__c)itemSObjs[0]).vlocity_cmt__FulfilmentRequestID__r.vlocity_cmt__AccountId__c;

            vlocity_cmt__FulfilmentRequestLine__c myFRL = (new Map<Id, vlocity_cmt__FulfilmentRequestLine__c>((vlocity_cmt__FulfilmentRequestLine__c[])itemSObjs)).get(item.vlocity_cmt__FulfilmentRequestLineId__r.Id);
        }

        Map<String, Object> payload = new Map<String, Object> {
            'order_items' => new List<Map<String, Object>>(),
            'account_id' => accountId,
            'order_id' => orderId
        };

        Map<String, List<Map<String, Object>>> lnChildItemsMap = new Map<String, List<Map<String, Object>>>(); // The order_items collection where the current item is put
        lnChildItemsMap.put('', (List<Map<String, Object>>)payload.get('order_items'));

        for (SObject itemSObj : itemSObjs) {
            String lineNumber = (String)itemSObj.get('vlocity_cmt__LineNumber__c');
            if (itemSObj.getSObjectType() == vlocity_cmt__FulfilmentRequestLine__c.SObjectType) {
                lineNumber = lineNumber.substringAfter('.');
            }
            System.debug('lineNumber: ' + lineNumber);
            // System.debug(itemSObj.get('vlocity_cmt__JSONAttribute__c'));
            String parentLineNumber = lineNumber.length() == 4 ? '' : lineNumber.subString(0, lineNumber.length() - 5);
            List<Map<String, Object>> childItems = lnChildItemsMap.get(parentLineNumber);

            // Parse JSON attribute for described_by node
            List<Map<String, Object>> described_by = new List<Map<String, Object>>();
            if (itemSObj.get('vlocity_cmt__JSONAttribute__c') != null) {
                vlocity_cmt.JSONAttributeSupport jsonSupport = new vlocity_cmt.JSONAttributeSupport();
                Map<String, object> inputMap = new Map<String, object>{
                    'UseDisplayTextForValues' => false,
                    'JSONString' => (String)itemSObj.get('vlocity_cmt__JSONAttribute__c')
                }; 
                Map<String, object> outputMap = new Map<String, object>(); 
                Map<String, object> optionsMap = new Map<String, object>();
        
                jsonSupport.invokeMethod('getAttributeValuesFromJSON', inputMap, outputMap, optionsMap); 
                Map<String, Object> attrValMap = (Map<String, Object>)outputMap.get('attributeCodeToValue');
                Map<String, Object> attrNameMap = (Map<String, Object>)outputMap.get('attributeCodeToDisplayName');
                // System.debug('outputMap: ' + JSON.serialize(outputMap));

                for (String attrCode : attrValMap.keySet()) {
                    described_by.add(new Map<String, Object> {
                        'value' => attrValMap.get(attrCode),
                        'characteristic' => attrNameMap.get(attrCode),
                        'characteristic_code' => attrCode
                    });
                }
            }

            //
            Map<String, Object> order_item = new Map<String, Object> {
                'order_items' => new List<Map<String, Object>>(),
                'described_by' => described_by,
                'specified_by' => new Map<String, Object> {
                    'specification_id' => itemSObj.get('vlocity_cmt__Product2Id__c'),
                    'specification_name' => itemSObj.getSObject('vlocity_cmt__Product2Id__r').get('Name')
                },
                'action' => itemSObj.get('vlocity_cmt__Action__c'),
                'order_item_id' => itemSObj.Id
            };
            childItems.add(order_item);
            // Add to the LineNumber and order_items to the Map
            lnChildItemsMap.put(lineNumber, (List<Map<String, Object>>)order_item.get('order_items'));
        }
        
        return payload;
    }

    /**
    * This method is called from executeItem to create M6 RequestType 
    *
    * @param  url  base URL for the batch
    * @param  method method for the batch
    * @param  input payload to be used to construct 
    * @return         M6 RequestType object to be sent
    */
    global abstract Boolean login(String url, vlocity_cmt__OrchestrationItem__c item);

    /**
     * This method returns the initial JSON payload from the given OrchestrationItem item
     * @param  url  base URL for the batch
     * @param  method method for the batch
     * @param  item Orchestration Item
     * @return      initial payload 
     */
    public virtual String generatePayload(vlocity_cmt__OrchestrationItem__c item, Map<String, Object> dataMap) {
        Object input = dataMap;
        // Execute the RequestItem DataRaptor
        if (item.vlocity_cmt__RequestItemsVlocityDataRaptorBundleId__c != null) {
            vlocity_cmt.DRProcessResult result = vlocity_cmt.DRGlobal.process((Map<String, Object>)input, item.vlocity_cmt__RequestItemsVlocityDataRaptorBundleId__c);
            input = result.toJSON();
        }

        // Execute the Request DataRaptor
        if (item.vlocity_cmt__VlocityDataRaptorBundleId__c != null) {
            vlocity_cmt.DRProcessResult result = vlocity_cmt.DRGlobal.process((Map<String, Object>)input, item.vlocity_cmt__VlocityDataRaptorBundleId__c);
            input = result.toJSON();
        }        

        return JSON.serialize(input);
    }    
    
    /**
    * This method is called from executeItem to create M6 RequestType 
    *
    * @param  url  base URL for the batch
    * @param  method method for the batch
    * @param  input payload to be used to construct 
    * @return         M6 RequestType object to be sent
    */
    global abstract Object createWSRequest(String methodName, String payload);

    /**
    * This method is called from executeItem to create process response
    *
    * @param  url  base URL for the batch
    * @param  method method for the batch
    * @param  respType M6 ResponseType to process
    * @return         output object to be processed
    */
    global abstract Map<String, Object> invokeWSMethod(String methodName, Object respType);

    /**
    * This method is called from executeItem to create process response
    *
    * @param  url  base URL for the batch
    * @param  method method for the batch
    * @param  respType M6 ResponseType to process
    * @return         output object to be processed
    */
    global abstract Map<String, Object> processWSResponse(String methodName, Object respType);


}
