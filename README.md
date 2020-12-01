# Portability Policy - DSAR Manager Demo App

![DSAR Manager Compressed](https://user-images.githubusercontent.com/7586106/100683126-8baed300-332c-11eb-8dc7-e5b5d13d8485.gif)

### Pre Requisites

This app requires a demo org with Privacy Center and Portability Policies enabled. The TA and Security Architect teams are working to make these available in the DXDO in the upcoming weeks. In the meanwhile you can use the License Editor within Blacktab to assign a **PrivacyCenter** add-on license to your demo org.

### Installation Instructions

### Option 1
Install the unlocked package in your org by accessing the following URL -
https://login.salesforce.com/packaging/installPackage.apexp?p0=04t4x000000cY5bAAE
**NOTE** The package requires Privacy Center to be enabled in your org. The package installation will fail if Privacy Center and the Portability Policy feature is not available in the org.

### Option 2
Clone the GitHub repository and deploy to a demo org or scratch org with Privacy Center enabled.
**NOTE** - There is no Feature setting for enabling Privacy Center in scratch orgs. Use the [Org Shape feature](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_shape_intro.htm) to create a scratch org based on an org that has Privacy Center enabled.

### Post Installation Instructions

1. Navigate to Setup and update the **Salesforce_Instance** Remote Site Setting to your demo org’s my domain URL.
2. Assign the **DSAR Perm Set** to required users.
3. Create a Portability Policy if one doesn’t exist.
4. You are all set.

### Usage Instructions

1. Click on App Launcher and access the DSAR Manager App.
2. Select a Portability Policy.
3. Select an Object. **IMPORTANT** The Object you choose should be one of the objects included in the Portability Policy. The DSAR would result in an error if an appropriate object is not chosen.
4. Search for and select the record against which you want to execute the Portability Policy.
5. Click **Send** .
6. A new record is added to the Data Subject Access Request List.
7. If the submission of the request is successful, the status of the request is updated from **Submitted** to **In Progress**.
8. Give it a few seconds and click on the 🔁 button next to the record.
9. If successful, the Status of the request will update to **Complete** and the **Policy File URL** will become available.
10. Click on the **Policy File URL** for that DSAR record. The policy file will download to your machine.
11. Open the file and show the contents of the file to the demo audience.

### Salesforce DX References

- [Salesforce Extensions Documentation](https://developer.salesforce.com/tools/vscode/)
- [Salesforce CLI Setup Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_intro.htm)
- [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_intro.htm)
- [Salesforce CLI Command Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference.htm)
