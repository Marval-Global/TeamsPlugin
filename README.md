
# Teams Plugin for MSM

This plugin facilitates the Teams integration for Marval

## Compatible Versions

| Plugin  | MSM         |
|---------|-------------|
| 1.0.0   | 15+         |


## Installation

To install the plugin, click on 'Activate Teams Integration'.
This creates an instance of Teams for you on the chatbot server by creating a public/private key pair and assigning a secret key for communications.
The next steps that need to be taken are the following:

* Creation of the chatbot and App Registration in your Azure Tenant.
* Setting up the chatbot tab in Self Service Customisation.
* Creation of an App Registration with the permissions `User.ReadBasic.All`, setting the application ID under Application (Client) ID in the plugin page.

There are a number of ways to configure the chatbot to use alternative permission methods, via the aadObject GUID Location drop-down shown after enabling the plugin:

* Choose "In Marval" if you use Entra for authentication; this is the fastest and simplest method if it is available in your system.
* Choose "From Microsoft" if you have/would prefer to set up an app registration in your Azure Tenant that has the permissions mentioned above.
* Choose "In an Attribute" for the plugin to retrieve the aadObjectId of the user from a user attribute in Marval, with the name of such an attribute under "Attribute Name".


## Contributing

We welcome all feedback including feature requests and bug reports. Please raise these as issues on GitHub. If you would like to contribute to the project please fork the repository and issue a pull request.