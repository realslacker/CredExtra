# turn on informational messages
$InformationPreference = 'Continue'

# load localized language
Import-LocalizedData -BindingVariable 'Messages' -FileName 'Messages' -BaseDirectory (Join-Path $ScriptPath 'lang')

# enum for username translation context
enum TranslateContext {
    Domain                  = 1 #ADS_NAME_INITTYPE_DOMAIN
    Server                  = 2 #ADS_NAME_INITTYPE_SERVER
    GlobalCatalog           = 3 #ADS_NAME_INITTYPE_GC
}

# enum for username translation types
enum TranslateType {
    DistinguishedName       = 1 #ADS_NAME_TYPE_1779
    CanonicalName           = 2 #ADS_NAME_TYPE_CANONICAL
    NTAccount               = 3 #ADS_NAME_TYPE_NT4
    DisplayName             = 4 #ADS_NAME_TYPE_DISPLAY
    DomainSimple            = 5 #ADS_NAME_TYPE_DOMAIN_SIMPLE
    EnterpriseSimple        = 6 #ADS_NAME_TYPE_ENTERPRISE_SIMPLE
    GUID                    = 7 #ADS_NAME_TYPE_GUID
    Unknown                 = 8 #ADS_NAME_TYPE_UNKNOWN
    UserPrincipalName       = 9 #ADS_NAME_TYPE_USER_PRINCIPAL_NAME
    CanonicalEx             = 10 #ADS_NAME_TYPE_CANONICAL_EX
    ServicePrincipalName    = 11 #ADS_NAME_TYPE_SERVICE_PRINCIPAL_NAME
    SID                     = 12 #ADS_NAME_TYPE_SID_OR_SID_HISTORY_NAME
}

