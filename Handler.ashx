<%@ WebHandler Language="C#" Class="Handler" %>

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
    private string ExcludeDescriptionMatch { get; set; }                            
    private string CustomerGUID { get { return this.GlobalSettings["@@CustomerGUID"]; } }
    private string CustomerName { get { return this.GlobalSettings["@@CustomerName"]; } }
  

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
    catch (Exception ex)
    {
        Log.Error(ex, "Error in PostRequest method");
        return "Error: " + ex.Message;
    }
}

    public override void HandleRequest(HttpContext context)
    {
        var param = context.Request.HttpMethod;  
        var browserObject = context.Request.Browser;

        MsmRequestNo = !string.IsNullOrWhiteSpace(context.Request.Params["requestNumber"]) ? int.Parse(context.Request.Params["requestNumber"]) : 0;
        lastLocation = !string.IsNullOrWhiteSpace(context.Request.Params["lastLocation"]) ? int.Parse(context.Request.Params["lastLocation"]) : 0;

        // AssignmentGroups = this.GlobalSettings["IncludeAssigneePrimaryGroup"];

        this.MarvalHost = context.Request.Params["host"] ?? string.Empty;

        // ExcludeDescriptionMatch = this.GlobalSettings["ExcludeDescriptionMatch"];


        switch (param)
        {
         case "GET":
           var getParamVal = context.Request.Params["endpoint"] ?? string.Empty;
           if (getParamVal == "createTeams") {
            var response = PostRequest("https://chatbot.marval.cloud/api/server/","");
            Log.Information("Have data2 " + response);
            context.Response.Write("Hi");

           } else if (getParamVal == "databaseValue") {
             // string json = this.GetCustomersJSON(lastLocation,AssignmentGroups,ExcludeDescriptionMatch);
             
             // context.Response.Write(json);
              } else if (getParamVal == "GoogleMapsAPIKey") {
              //    context.Response.Write(GoogleMapsAPIKey); 
            } else {
               context.Response.Write("No valid parameter requested");
            }
            break;
          case "POST":
             var hostSource = context.Request.Form["hostSource"];
             var customerName = context.Request.Form["customerName"];
             var action = context.Request.Form["action"];
             Log.Information("Have hostsource as " + hostSource);
             Log.Information("Have customerName as " + customerName);
             Log.Information("Have action as " + action);
             if (action == "createTeams") {
                var response = PostRequest("https://chatbot.marval.cloud/api/server/createCustomer","{ \"hostSource\": \"" + hostSource + "\", \"customerName\": \"" + customerName + "\"}");
                Log.Information("Have data2 back as " + response);
                context.Response.Write(response);
                
             } else if (action == "") {

             } else {

             }
             break;
        }
    }
}

