<%@ WebHandler Language = "C#" Class="Handler" %>

using System;
using System.IO;
using System.Net;
using System.Xml;
using System.Xml.Linq;
using System.Xml.Serialization;
using System.Collections.Generic;
using System.Text;
using System.Threading;
using Serilog;
using System.Web.Script.Serialization;
using System.Web;
using MarvalSoftware.UI.WebUI.ServiceDesk.RFP.Plugins;
using System.Linq;
using System.Xml.Linq;
using System.Data;
using System.Data.SqlClient;
using Microsoft.Win32;

public class Handler : PluginHandler
{

    private string APIKey { get; set; }

    private string Password { get; set; }
    private string Username { get; set; }
    private string Host { get; set; }

    private string DBName { get; set; }
    private string MarvalHost { get; set; }
    private string AssignmentGroups { get; set; }
    private string CustomerGUID { get { return this.GlobalSettings["@@CustomerGUID"]; } }
    private string ClientID { get { return this.GlobalSettings["@@ClientID"]; } }
    private string TenantID { get { return this.GlobalSettings["@@TenantID"]; } }
    private string CustomerName { get { return this.GlobalSettings["@@CustomerName"]; } }
    private string AADObjectGUIDLocation { get { return this.GlobalSettings["@@AADObjectGUIDLocation"]; } }


    private int MsmRequestNo { get; set; }

    private int lastLocation { get; set; }

    // private string Password = this.GlobalSettings["RequestAttributeTypeId"];   
    public override bool IsReusable { get { return false; } }


    private string PostRequest(string url, string data)
    {
        try
        {
            // Create a web request
            HttpWebRequest request = (HttpWebRequest)WebRequest.Create(url);
            request.Method = "POST";
            request.ContentType = "application/json";

            // Write data to request body
            using (StreamWriter writer = new StreamWriter(request.GetRequestStream()))
            {
                Log.Information("Have data " + data);
                writer.Write(data);
            }

            // Get response
            using (HttpWebResponse response = (HttpWebResponse)request.GetResponse())
            {
                using (StreamReader reader = new StreamReader(response.GetResponseStream()))
                {
                    return reader.ReadToEnd();
                }
            }
        }
        catch (WebException webEx)
        {
            // If we have a response, we can read the error message from the response body
            if (webEx.Response != null)
            {
                using (var errorResponse = (HttpWebResponse)webEx.Response)
                {
                    using (var reader = new StreamReader(errorResponse.GetResponseStream()))
                    {
                        string errorText = reader.ReadToEnd();
                        // Return or log the error text
                        Log.Information("Response error is ", errorText);
                        return errorText;
                    }
                }
            }

            // If we have no response, return the exception message
            return webEx.Message;
        }
        catch (Exception ex)
        {
            // Handle other exceptions
            return ex.ToString();
        }
    }

    public override void HandleRequest(HttpContext context)
    {
        var param = context.Request.HttpMethod;
        var browserObject = context.Request.Browser;

        MsmRequestNo = !string.IsNullOrWhiteSpace(context.Request.Params["requestNumber"]) ? int.Parse(context.Request.Params["requestNumber"]) : 0;
        lastLocation = !string.IsNullOrWhiteSpace(context.Request.Params["lastLocation"]) ? int.Parse(context.Request.Params["lastLocation"]) : 0;

        this.MarvalHost = context.Request.Params["host"] ?? string.Empty;

        switch (param)
        {
            case "GET":
                var getParamVal = context.Request.Params["endpoint"] ?? string.Empty;
                if (getParamVal == "createTeams")
                {
                    var response = PostRequest("https://chatbot.marval.cloud/api/server/", "");
                    Log.Information("Have data2 " + response);
                    context.Response.Write("Hi");

                }
                else if (getParamVal == "ClientID")
                {
                    context.Response.Write(ClientID);
                }
                else if (getParamVal == "TenantID")
                {
                    context.Response.Write(TenantID);
                }
                else if (getParamVal == "databaseValue")
                {
                    string json = this.GetCustomersJSON(context.Request.Params["CIId"]);

                    context.Response.Write(json);
                }
                else if (getParamVal == "AADObjectGUIDLocation")
                {
                    context.Response.Write(AADObjectGUIDLocation);
                } else {
                    context.Response.Write("No valid parameter requested");
                }
                break;
            case "POST":
                var hostSource = context.Request.Form["hostSource"];
                var customerName = context.Request.Form["customerName"];
                var tenantId = this.TenantID;
                var action = context.Request.Form["action"];
                Log.Information("Have hostsource as " + hostSource);
                Log.Information("Have customerName as " + customerName);
                Log.Information("Have action as " + action);
                if (action == "createTeams")
                {
                    try
                    {
                        // Construct the request payload


                        // Make the POST request
                        var response = PostRequest("https://chatbot.marval.cloud/api/server/createCustomer", "{ \"tenantId\": \"" + tenantId + "\", \"hostSource\": \"" + hostSource + "\", \"customerName\": \"" + customerName + "\"}");
                        Log.Information("Have data2 back as " + response);
                        // context.Response.Write(context.Response.StatusCode);
                        // Write the response back
                        context.Response.Write(response);
                    }
                    catch (Exception ex)
                    {
                        // Log the error
                        //  Log.Error("Error occurred while creating teams: " + ex.Message, ex);
                        Log.Information("Error in createCustomer method" + ex);
                        // Return an error response
                        context.Response.StatusCode = 500; // Internal Server Error
                        context.Response.ContentType = "application/json";
                        context.Response.Write("{\"error\":\"An error occurred while processing your request.\"}");
                    }
                }
                else if (action == "")
                {

                }
                else
                {

                }
                break;
        }
    }

    private string GetDBString()
    {
        string connectionString = "";

        string msmdLocation = GetAppPath("MSM");
        string path = msmdLocation;
        string newPath = Path.GetFullPath(Path.Combine(path, @"..\"));
        string openFilePath = newPath + "connectionStrings.config";

        XmlDocument xmlDoc = new XmlDocument();
        xmlDoc.Load(openFilePath);

        XmlNodeList nodeList = xmlDoc.SelectNodes("/appSettings/add[@key='DatabaseConnectionString']");

        if (nodeList.Count > 0)
        {
            // Get the value attribute of the node
            connectionString = nodeList[0].Attributes["value"].Value;
        }
        else
        {
            Log.Information("Could not find connection string on the local machine");
        }
        return connectionString;
    }
    private string GetAppPath(string productName)
    {
        const string foldersPath = @"SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\Folders";
        var baseKey = RegistryKey.OpenBaseKey(RegistryHive.LocalMachine, RegistryView.Registry64);

        var subKey = baseKey.OpenSubKey(foldersPath);
        if (subKey == null)
        {
            baseKey = RegistryKey.OpenBaseKey(RegistryHive.LocalMachine, RegistryView.Registry32);
            subKey = baseKey.OpenSubKey(foldersPath);
        }
        return subKey != null ? subKey.GetValueNames().FirstOrDefault(kv => kv.Contains(productName)) : "ERROR";
    }

    private string GetCustomersJSON(string CIId)
    {
        string connString = GetDBString();
        using (SqlConnection conn = new SqlConnection())
        {
            conn.ConnectionString = connString;
            using (SqlCommand cmd = new SqlCommand())
            {
                cmd.CommandText = "select guid from directoryRelationship where CIId = " + CIId;
                cmd.Connection = conn;
                conn.Open();
                string returnVal = "";
                using (SqlDataReader sdr = cmd.ExecuteReader())
                {
                    sdr.Read();
                    returnVal = Convert.ToString(sdr["guid"]);
                }
                conn.Close();

                return returnVal;
            }
        }
    }

}
