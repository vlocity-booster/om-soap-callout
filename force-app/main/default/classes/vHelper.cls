public with sharing class vHelper {
    /*
     * @description utiliy method to read the attribute value from JSONAttribute field
     */
    public static Map<String, Object> getJSONAttributeValues(String jsonAttribute) {
        vlocity_cmt.JSONAttributeSupport jsonSupport = new vlocity_cmt.JSONAttributeSupport();
        // Read the old speed
        Map<String, object> inputMap = new Map<String, object>{
            'UseDisplayTextForValues' => false,
            'JSONString' => jsonAttribute
        }; 
        Map<String, object> outputMap = new Map<String, object>(); 
        Map<String, object> optionsMap = new Map<String, object>();

        jsonSupport.invokeMethod('getAttributeValuesFromJSON', inputMap, outputMap, optionsMap); 
        Map<String, Object> attrVals = (Map<String, Object>)outputMap.get('attributeCodeToValue');
        return attrVals;
        // return attrVals.get(attribCode);
    }    

    /*
     * @description utiliy method to read the attribute value from JSONAttribute field
     */
    public static Object getJSONAttributeValue(String jsonAttribute, String attribCode) {
        return getJSONAttributeValues(jsonAttribute).get(attribCode);
    }     
}
