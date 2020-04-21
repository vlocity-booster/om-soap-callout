global with sharing abstract class WSBaseSystemInterface implements vlocity_cmt.XOMOrchestrationInterfaces.ISystemInterface, vlocity_cmt.XOMOrchestrationInterfaces.IDeferredUpdater {
    public class WSBaseSystemInterfaceException extends Exception {}

    global WSBaseSystemInterface() {

    }

    /**
    * This method is a part of ISystemInterface. It is invoked at the start of the batch
    * @param  url  base URL the batch is started for
    * @param  path path this batch is started for
    */
    global virtual void startBatch(String url, String path){
        // Do nothing
    }

    /**
    * Executes a Callout OrchestrationItem
    * if cache is enabled then orchestration item data is retrieved from cache
    * @param  url  base URL to send the request to
    * @param  path path to send the request to
    * @param  item OrchestrationItem that needs to be executed
    */
    global virtual void executeItem(String url, String path, vlocity_cmt__OrchestrationItem__c item) { 

    }

    /**
    * This method is called at the end of the batch
    * @param  url  base URL for the batch
    * @param  path path for the batch
    */
    global virtual void endBatch(String url, String path) {
        // Do nothing
    }

    /**
    * update DB,
    * from XOMOrchestrationInterfaces, executed when it safe to do it.
    */
    public void updateDatabase() {
    }

    /**
    * This method is called from executeItem to create M6 RequestType 
    *
    * @param  url  base URL for the batch
    * @param  path path for the batch
    * @param  input payload to be used to construct 
    * @return         M6 RequestType object to be sent
    */
    public virtual Map<String, Object> invokeMethod(String url, String path, Map<String, Object> input) {
        return null;
    } 

    /**
    * This method is called from executeItem to create M6 RequestType 
    *
    * @param  url  base URL for the batch
    * @param  path path for the batch
    * @param  input payload to be used to construct 
    * @return         M6 RequestType object to be sent
    */
    global abstract Boolean login(String url, String path);

    
    /**
    * This method is called from executeItem to create M6 RequestType 
    *
    * @param  url  base URL for the batch
    * @param  path path for the batch
    * @param  input payload to be used to construct 
    * @return         M6 RequestType object to be sent
    */
    global abstract Object createWSRequest(String methodName, Map<String, Object> input);

    /**
    * This method is called from executeItem to create process response
    *
    * @param  url  base URL for the batch
    * @param  path path for the batch
    * @param  respType M6 ResponseType to process
    * @return         output object to be processed
    */
    global abstract Map<String, Object> exexcuteWSMethod(String methodName, Object respType);

    /**
    * This method is called from executeItem to create process response
    *
    * @param  url  base URL for the batch
    * @param  path path for the batch
    * @param  respType M6 ResponseType to process
    * @return         output object to be processed
    */
    global abstract Map<String, Object> processWSResponse(String methodName, Object respType);


}
