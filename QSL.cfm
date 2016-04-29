<cfsilent>
<!---
 
Copyright 2008 Christopher Dean

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License. 
You may obtain a copy of the License at 
	http://www.apache.org/licenses/LICENSE-2.0 
Unless required by applicable law or agreed to in writing, 
software distributed under the License is distributed on an "AS IS" BASIS, 
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
See the License for the specific language governing permissions 
and limitations under the License.


***************************************************************************************
Name: qsl.cfm

Custom tag to output a "Quick Scan List" of output table rows and all you to expand
and collapse a detail page within the rows.  Note this tag relies upon the blank.html
file to be present inorder to get around the IE mixed-mode warnings for SSL sites.  

The tag has the ability to redraw itself (i.e. re-run the query) based upon the value
of the javascript variable resetQSL in the global scope of the page using this tag.  Your
detail pages can reference this variable as parent.resetQSL and can set it to 'false' or
'true' if a field present in the QSL was changed in the detail and thus needs to be reflected
in the QSL or as a result of the detail page the rows to show has changed.

Also make sure your CF_QSL tag in your main display page (not the QSLpage) has a div with the
id=resultsdiv surrounding it like so:

<div id="resultsdiv">
 <cf_qsl ....>
</div>

This will ensure that the ajax features such as sorting and next/prev and reseting of the QSL
work.

Attributes:

description = a description of what's in the table, used as a title for table
results = the query result set
resultsname = the name of the cold fusion result set variable (deprecated - only for backward compatibility
headerColumns = a list of the actual db column names for each column of the table
header = a list of the header descriptions (english versions of column names)
headerTypes = a list of header types (STRING, BOOLEAN, TEXT, DATE, TIME, TIMESTAMP, INTEGER, REAL, CUSTOM[see below]) for each column, defaults to all STRING types>
detailpage = the URL to display when the View button is clicked (if blank then no view button)
detailpageheight = the size of the detail page window in pixels (default 210)
detailpageincrement = the pixel increment of the expand/collapse of the detail page window which needs to be factor of the detail page height (page height mod increment = 0) 
displayheight = if specified the table will be a fixed sized and will be scrollable as additional entries are displayed or expanded/collapsed
qslpage = the URL of the results page to call via ajax when doing a next/prev or sort
startindex = the starting index in the result set
maxrows = how many rows to show per page
key = the key db column name, will be passed in as a form parameter to the detail page
keytype = the type of the key column
query = the query used to generate the table, will be passed in as a form parameter to the detail page
backcounter = name of the javascript variable that will hold the backcounter.  Each click of the View button
   increases the page history by 2, so the code will automatically substract 2 each time you click it and
   any backbutton in the main frame must do a history.back(backcounter);backcounter=-1; in its onclick method.
   In the main frame that calls QSL have a "var backcounter =  -1" line of javascript 
evenbgcolor = background color of even rows (default #CCCCCC)
oddbgcolor = background color of odd rows (default #FFFFFF)
color = text color of rows (default #000000)
fontsize = font size of row text (default small)
headerfontsize = font size of header text (default medium)>
fontfamily = font family (default tahoma)
headercolor = text color of header (default #000000)
headerbgcolor = background color of header (default #AAAAAA)
headerlinkcolor = link color of header titles for sorting (default blue)
highlightbgcolor = background color of row that is highlighted (default #777777)
highlightcolor = color of text of a row that is highlighted (default #FFFF00)
dateformat = format you want to have dates displayed in (default mm/dd/yyyy)
timeformat = format you want to have times displayed in (default HH:mm:ss)
buttonclass = style class from an external stylesheet for all the buttons (default is empty)
allowsorting = allow the column links to sort (default: true)
mappings = cold fusion component instance that defines the following method: getBackwardValueMapping(attribute,value).

           When calling the tag use the format mappings="#ValueMappings#" where ValueMappings is a result of a
           createObject("component","ValueMappings") or similar call.

           The method will take a column name (from headerColumns) and a value and return the english version.  For example:

	
           <cfcomponent displayname="ValueMappings">

           <cffunction name="getBackwardValueMapping" access="public" output="no" returntype="String">

	          <cfargument name="attribute" type="String" required="yes">
	          <cfargument name="value" type="String" required="yes">
	  
	          <cfif attribute eq "WORKTYPE">
	            <cfswitch expression="#value#">
                  <cfcase value="CAL">
			        <cfreturn "CAL - Calibration">
			      </cfcase>
                  <cfcase value="PROJ">
			        <cfreturn "PROJ - Capital Projects">
			      </cfcase>			
			      ....
	            </cfswitch>
	          </cfif>
	       <cfreturn value>
         </cffunction>
         </cfcomponent>

customcolumn = cold fusion component instance that defines the following method: outputCustomColumn(attribute,instancevalues).
               By defining a column as having type CUSTOM, this component method will be called with the attribute name and
			   a struct containing all the values of the instance.  This is to allow you to add graphic alerts or other messages
			   based upon the values of the instance.  It should be called as custommapping="#customoutputcomponent#".
			   The method will need to have output="yes" and return the HTML code that will go inside the table data element (TD).
			   For example:
			   
          <cfcomponent displayname="CustomOutput">

           <cffunction name="outputCustomColumn" access="public" output="yes" returntype="void">

	          <cfargument name="attribute" type="String" required="yes">
	          <cfargument name="instancevalues" type="Struct" required="yes">
	  
	          <cfif attribute eq "ISDUPLICATE">
	             
	             <cfset id = StructFind(instancevalues,"ID")>
	             <cfif Left(id,1) eq "7">
	                <!-- id's that start with 7 are duplicates -->
	                <b>TRUE</b>
	             </cfif>
	          <cfelse>
	              &nbsp;   <!-- error case -->
	          </cfif>
	  
         </cffunction>
         </cfcomponent>			 
			
	
	

Detail page:

The Detail page will be called when you hit the view button on a row.  It will be passed
4 form parameters:

QUERY: The query that generated the QSL
ROWKIND: tr_even for an even row, tr_odd for an odd row if you want to adjust your detail to match any colors
DETAILKEYVALUE: The value of the key for the detail (NOTE: only single key columns are currently supported so if you need multiple, create a view)
DETAILKEYTYPE: The type of the key column as mentioned above.  The Key name is not passed since your destination
page is custom and should know.  It should also know the type for that matter and probably won't need it either

Example:

<cfset keyvalue = DETAILKEYVALUE>
<cfif IsDefined('DETAILKEYTYPE')>
  <cfif DETAILKEYTYPE eq "STRING" OR DETAILKEYTYPE eq "TEXT" OR DETAILKEYTYPE eq "DATE" OR DETAILKEYTYPE eq "TIME" OR DETAILKEYTYPE eq "TIMESTAMP">
     <cfset keyvalue = "'" & keyvalue & "'">
  </cfif>
</cfif>

<cfquery name="detail" dataSource="cfmaxread">

SELECT ACTFINISH,ACTLABHRS,ACTSTART,DESCRIPTION,DISABLED,
DOWNTIME,EQNUM,ESTDUR,FOLLOWUPFROMWONUM,
GENERATEDFORPO,GENFORPOLINEID,HASCHILDREN,HASFOLLOWUPWORK,
INTERRUPTABLE,LOCATION,PARENT,PHONE,REPORTDATE,
REPORTEDBY,SCHEDFINISH,SCHEDSTART,STATUS,STATUSDATE,
SUPERVISOR,TARGCOMPDATE,TARGSTARTDATE,WONUM,WORKTYPE,
WOPRIORITY, HISTORYFLAG, ISTASK 
FROM WORKORDER WHERE WORKORDER.WONUM = #PreserveSingleQuotes(KEYVALUE)# 
</cfquery>

QSLpage:

The QSLpage is called when the next or prev buttons are pressed or a column is sorted.  It will be passed
the followiing form parameters:

ORDERBY:  The order by clause if a column is being sorted
QUERYSEARCH: The query that generated the quick scan list with or without an order by clause
SORTORDER: ASC or DESC when sorting a column
HEADER: the header column titles originally passed into the tag
HEADERCOLUMNS: the header columns originally passed into the tag
HEADERTYPES: the header column types originally passed into the tag (see above)
START: The starting row to display

In the QSLPage you must run the original query again and call the QSL custom tag again with these form parameters and the query
with the order by attached properly.  The result will be displayed in the original QSL table using
the innerHTML element of the table.

For example:

<cfif IsDefined('FORM.ORDERBY')>
   <cfset querySearch = FORM.querySearch>
   <cfset index = FindNoCase("ORDER BY ",querySearch)>
   <cfif index neq 0>
      <!--- strip off existing order by and add our own --->

      <cfset querySearch = Left(querySearch,index-1)>
   </cfif>
   <cfset querySearch = querySearch & " ORDER BY " & FORM.ORDERBY>
</cfif>

<cfquery name="wosresults" datasource="cfmaxread"> #PreserveSingleQuotes(querySearch)# </cfquery>
<cfif IsDefined('FORM.SORTORDER')>
   <cf_QSL results="#wosresults#" mappings="#application.wosValueMappings#" description="Work Orders" sortorder="#FORM.SORTORDER#" header="#FORM.header#" headerColumns="#FORM.headerColumns#" headerTypes="#FORM.headerTypes#" detailpage="wosDetail.cfm" qslpage="wosResultsAjax.cfm" start="#FORM.start#" pageRows="50" query="#querySearch#" key="WONUM" keytype="STRING" backcounter="backcounter"> 
<cfelse>
   <cf_QSL results="#wosresults#" mappings="#application.wosValueMappings#" description="Work Orders" header="#FORM.header#" headerColumns="#FORM.headerColumns#" headerTypes="#FORM.headerTypes#" detailpage="wosDetail.cfm" qslpage="wosResultsAjax.cfm" start="#FORM.start#" pageRows="50" query="#querySearch#" key="WONUM" keytype="STRING" backcounter="backcounter"> 
</cfif>


***************************************************************************************
--->

<cfif IsDefined('attributes.resultsname')>
   <cfset thistag.result = Evaluate("Caller." & attributes.resultsname)>
<cfelse>
   <cfset thistag.result = attributes.results>
</cfif>

<cfif IsDefined('Attributes.headerTypes')>
   <cfset thistag.headerTypes = Attributes.headerTypes>
<cfelse>
   <cfset thistag.headerTypes  = "STRING">
   <cfloop index="i" from="2" to="#ListLen(attributes.headerColumns)#">
     <cfset thistag.headerTypes = headerTypes & ",STRING">
   </cfloop>
</cfif>


<cfparam name="attributes.startindex" default="1" type="integer">
<cfset startindex = attributes.startindex>
<cfparam name="attributes.pageRows" default="50" type="integer">
<cfset max_rows = attributes.pageRows>
<cfset end = thistag.result.RecordCount>
<cfset thistag.numberOfColumns = ListLen(attributes.headerColumns)>
<cfif ListContains(attributes.headerTypes,"CUSTOM") or ListContains(attributes.headerTypes,"custom")>
  <cfset thistag.customtypes = true>
<cfelse>
  <cfset thistag.customtypes = false>
</cfif>
<cfset thistag.keyname  = "thistag.result." & attributes.key>
<cfset thistag.backcounter_name = attributes.backcounter>

<cfparam name="attributes.evenbgcolor" default="##CCCCCC" type="string">
<cfparam name="attributes.oddbgcolor" default="##FFFFFF" type="string">
<cfparam name="attributes.color" default="##000000" type="string">
<cfparam name="attributes.fontsize" default="small" type="string">
<cfparam name="attributes.headerfontsize" default="medium" type="string">
<cfparam name="attributes.fontfamily" default="tahoma" type="string">
<cfparam name="attributes.headercolor" default="##000000" type="string">
<cfparam name="attributes.headerbgcolor" default="##AAAAAA" type="string">
<cfparam name="attributes.headerlinkcolor" default="blue" type="string">
<cfparam name="attributes.highlightbgcolor" default="##777777" type="string">
<cfparam name="attributes.highlightcolor" default="##FFFF00" type="string">
<cfparam name="attributes.dateformat" default="mm/dd/yyyy" type="string">
<cfparam name="attributes.timeformat" default="HH:mm:ss" type="string">
<cfparam name="attributes.buttonclass" default="" type="string">
<cfparam name="attributes.detailpage" default="" type="string">
<cfparam name="attributes.allowsorting" default="true" type="boolean">
<cfparam name="attributes.detailpageheight" default="210" type="integer">
<cfparam name="attributes.detailpageincrement" default="35" type="integer">
</cfsilent>
<cfoutput>
	
<cfsavecontent variable="headtext">
<style>

TR.tr_even {
	background-color: #attributes.evenbgcolor#;
	color: #attributes.color#;
}

TR.tr_header {      
	font-family: #attributes.fontfamily#;
	background-color: #attributes.headerbgcolor#;
}

TR.tr_odd {             	
	background-color: #attributes.oddbgcolor#;
	color: #attributes.color#;			
}

TH.th_even {
	font-family: #attributes.fontfamily#;
	background-color: #attributes.headerbgcolor#;
	color: #attributes.headercolor#;
    font-size: #attributes.headerfontsize#;
    text-align: center;
    vertical-align: middle;
}


TBODY TD.Item {
  font-size: #attributes.fontsize#;
 
}
TBODY TD.ItemOver
{
	border: ridge  1px;
    color: #attributes.highlightcolor#;
    background-color: #attributes.highlightbgcolor#;
    font-size: #attributes.fontsize#;
}

A:link, A:visited 
{ 
      color: #attributes.headercolor#; 
      text-decoration : none; 	
}

A:hover 
{ 
      color: #attributes.headerlinkcolor#; 
      text-decoration : none; 	
}


/*td:last-child {padding-right: 20px;} */ /* prevent Mozilla scrollbar from hiding cell content */

</style>	

<script type="text/javascript">

  var xmlHttp=null;
  
  function createXMLHttpRequest()
  {
    if (window.ActiveXObject)
    {
      xmlHttp = new ActiveXObject("Microsoft.XMLHTTP");
    }
    else if (window.XMLHttpRequest)
    {
     
      xmlHttp = new XMLHttpRequest();
    }
  }

 
  
  function startRequest_range(request)
  {
      createXMLHttpRequest();
      xmlHttp.onreadystatechange = handleStateChange_range;
      xmlHttp.open("POST","#Attributes.qslpage#",true);
      xmlHttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded");
      xmlHttp.send(request);                      
  }
 
  function handleStateChange_range()
  {

      if (xmlHttp.readyState == 4)
      {
         if (xmlHttp.status == 200)
         {
            document.getElementById('resultsdiv').innerHTML = xmlHttp.responseText;
         }
         else
         {
            // this can return a 500 error if the CF page has a syntax error
            document.getElementById('resultsdiv').innerHTML = 'Server Error: ' + xmlHttp.status;
         }
                         
      }
  }
  
var lastview = null;

function viewhighlight(view,button) {
	
	if (lastview != null) {	
                if (view != lastview)
                {
		  document.getElementById(lastview).className='viewoff';
                  lastbutton.disabled=false;
                  document.getElementById(view).className='viewon';
                  button.disabled=true;
                  lastview = view;
                  lastbutton = button;
                }
	}
        else
        {
	  document.getElementById(view).className='viewon';
          button.disabled=true;
	  lastview = view;
          lastbutton = button;
        }
		
}


function MM_findObj(n, d) { //v4.01
  var p,i,x;  if(!d) d=document; if((p=n.indexOf("?"))>0&&parent.frames.length) {
    d=parent.frames[n.substring(p+1)].document; n=n.substring(0,p);}
  if(!(x=d[n])&&d.all) x=d.all[n]; for (i=0;!x&&i<d.forms.length;i++) x=d.forms[i][n];
  for(i=0;!x&&d.layers&&i<d.layers.length;i++) x=MM_findObj(n,d.layers[i].document);
  if(!x && d.getElementById) x=d.getElementById(n); return x;
}

function MM_showHideLayers() { //v6.0
  var i,p,v,obj,args=MM_showHideLayers.arguments;
  for (i=0; i<(args.length-2); i+=3) if ((obj=MM_findObj(args[i]))!=null) { v=args[i+2];
    if (obj.style) { obj=obj.style; v=(v=='show')?'visible':(v=='hide')?'hidden':v; }
    obj.visibility=v; }
}

function MM_expandCollapseLayers() { //v6.0
  var i,p,v,obj,args=MM_expandCollapseLayers.arguments;
  for (i=0; i<(args.length-2); i+=3) if ((obj=MM_findObj(args[i]))!=null) { v=args[i+2];
    if (obj.style) { obj=obj.style; v=(v=='show')?'block':(v=='hide')?'none':v; }
    obj.display=v; }
}




function setScope(objRow,objEvt,bitIsHighlight,DisplayCnt){
	var strCurrStyle, strRowStyle;
	
	if (bitIsHighlight) {
		strCurrStyle="ItemOver";
		strRowStyle="ItemOver";
	} else {
		strCurrStyle="Item";
		strRowStyle="Item";
	}
	
	var tdCntr;
	var lpCntr; 
	tdCntr=0;
	lpCntr=0;
    while ((tdCntr < (DisplayCnt )) && (lpCntr < (objRow.childNodes.length))){	
		if (objRow.childNodes[lpCntr].nodeName=="TD"){
			objRow.childNodes[lpCntr].className=strRowStyle;
			blnAlt=true;
			tdCntr=tdCntr+1;
		 }
		lpCntr+=1;
    }
	
}


var smooth_timer;

function smoothHeight(id, curH, targetH, stepH, mode) {
  diff = targetH - curH;
  if (diff != 0) {
    newH = (diff > 0) ? curH + stepH : curH - stepH;
    ((document.getElementById) ? document.getElementById(id) : eval("document.all['" + id + "']")).style.height = newH + "px";
    if (smooth_timer) window.clearTimeout(smooth_timer);
    smooth_timer = window.setTimeout( "smoothHeight('" + id + "'," + newH + "," + targetH + "," + stepH + ",'" + mode + "')", 15 );
  }
  else if (mode != "o") ((document.getElementById) ? document.getElementById(mode) : eval("document.all['" + mode + "']")).style.display="none";
}


function servOC(i, height, increment, numberOfColumns) {
  var trHide = (document.getElementById) ? document.getElementById('hide' + i) : eval("document.all['hide" + i + "']");
  var trObj = (document.getElementById) ? document.getElementById('ihtr' + i) : eval("document.all['ihtr" + i + "']");
  var ifObj = (document.getElementById) ? document.getElementById('ihif' + i) : eval("document.all['ihif" + i + "']");
  var qsltr = (document.getElementById) ? document.getElementById('qsltr' + i) : eval("document.all['qsltr" + i + "']");
  if (trObj != null) {
    if (trObj.style.display=="none") {
      ifObj.style.height = "0px";
      trObj.style.display="";
      trHide.style.display="";
      qsltr.style.display="none";  
      setScope(qsltr,null,0,numberOfColumns);
      smoothHeight('ihif' + i, 0, height, increment, 'o');
    }
    else {
      smoothHeight('ihif' + i, height, 0, increment, 'ihtr' + i);
      trHide.style.display="none";
      qsltr.style.display="";
    }
  }
}
  
var resetQSL = 'false'; //set by the detail page to indicate to re-run the QSL query when HIDE is pressed.  This is to handle QSL fields that could be changed via a detail screen  
  
</script>
 

</cfsavecontent>

<cfhtmlhead text="#headtext#">

<cfif thistag.result.RecordCount gt max_rows>
    <cfset to = startindex + max_rows - 1>
    <cfif to gt thistag.result.RecordCount>
       <cfset to = thistag.result.RecordCount>
    </cfif>
    <cfset countDisplay = "(#startindex#-#to# of #thistag.result.RecordCount#)">
<cfelse>
    <cfset countDisplay = "(#thistag.result.RecordCount#)">
</cfif>


</cfoutput>                 


<fieldset style="border-style: groove; border-width: thick; border-color: #999999; padding: 1px;">
    <legend><B><font size="+1" color="<cfoutput>#attributes.color#</cfoutput>"><cfoutput>#attributes.description# #countDisplay#</cfoutput></font></b></legend>

<cfif IsDefined('attributes.displayheight')>
   <div style="overflow: auto; height: <cfoutput>#attributes.displayheight#</cfoutput>px">
<cfelse>
   <div>
</cfif>
<table border="1" width="99%" cellspacing="0" cellpadding="2" bgcolor="transparent">
<!--- because this a custom tag now, the code must be in the tag since it may be in the custom tag directory

  <cfinclude template="QSLheader.cfm">
--->
  <thead>
  <tr class="tr_header">
    <th class="th_even">             

       <cfif thistag.result.RecordCount gt MAX_ROWS>
           <cfset pad = 0>
           <cfif STARTINDEX gt 1>
             <cfset pad = #Len(MAX_ROWS)#>
           </cfif>
		
		   <cfset pad = Len(thistag.result.RecordCount)>
           <cfif STARTINDEX gt 1>
               
               <cfset to = STARTINDEX - 1>
               <cfset from = STARTINDEX - MAX_ROWS>
               <cfset padstring = MAX_ROWS>
               <cfset len = pad - Len(MAX_ROWS)>
               <cfoutput>
               <cfloop index="i" from="1" to="#len#">
                   <cfset padstring = "0#padstring#">
               </cfloop>
               <cfset next = "Prev #padstring#">
               
               <cfset requestString = "start=#from#&querySearch=#URLEncodedFormat(attributes.query)#&header=#URLEncodedFormat(attributes.header)#&headerColumns=#URLEncodedFormat(attributes.headerColumns)#&headerTypes=#URLEncodedFormat(thistag.headerTypes)#">
 
                <form action="##" method="GET" style="margin-top: 0;margin-left: 0; margin-right: 0; margin-bottom: 0;">
                     <input type="button" class="#attributes.buttonclass#" value="#next#" onclick="startRequest_range('#requestString#');">                   
                </form>           
               </cfoutput>        
           </cfif>
           <cfset from = STARTINDEX+MAX_ROWS>
           <cfif from lte thistag.result.RecordCount>
              
               <cfset to = STARTINDEX + MAX_ROWS + MAX_ROWS>
               <cfif to gt thistag.result.RecordCount>
                  <cfset to = thistag.result.RecordCount+1>
               </cfif>
               <cfset padstring = to-(STARTINDEX+MAX_ROWS)>
               <cfset len = pad - Len(to-(STARTINDEX+MAX_ROWS))>
               <cfoutput>
               <cfloop index="i" from="1" to="#len#">
                   <cfset padstring = "0#padstring#">
               </cfloop>
               <cfset next = "Next #padstring#">
               <cfset requestString = "start=#from#&querySearch=#URLEncodedFormat(attributes.query)#&header=#URLEncodedFormat(attributes.header)#&headerColumns=#URLEncodedFormat(attributes.headerColumns)#&headerTypes=#URLEncodedFormat(thistag.headerTypes)#">
                 <form action="##" method="GET" style="margin-top: 0;margin-left: 0; margin-right: 0; margin-bottom: 0;">
 
                     <input type="button" class="#attributes.buttonclass#" value="#next#" onclick="startRequest_range('#requestString#');">
                   
                </form>
             
              </cfoutput>
           </cfif>
        
      <cfelse>
    
        &nbsp;
      </cfif>
    </th> 

    <cfoutput>
    <cfloop index="column" from="1" to="#ListLen(attributes.header)#">
		
      <cfset headerColumn = ListGetAt(attributes.headerColumns,column)> 
	  <cfset headerText = ListGetAt(attributes.header,column)>
      <th nowrap class="th_even">

         <cfif attributes.allowsorting eq "true">
         <cfset requestString = "start=#1#&querySearch=#URLEncodedFormat(attributes.query)#">
 		 <cfif IsDefined('Attributes.SORTORDER')>
	        <cfset requestString = requestString & "&ORDERBY=#URLEncodedFormat(headerColumn)#+#Attributes.SORTORDER#&header=#URLEncodedFormat(attributes.header)#&headerColumns=#URLEncodedFormat(attributes.headerColumns)#&headerTypes=#URLEncodedFormat(thistag.headerTypes)#">
   
		    <cfif Attributes.SORTORDER eq "DESC">
			    <cfset requestString = requestString & "&SORTORDER=ASC">
			<cfelse>
			    <cfset requestString = requestString & "&SORTORDER=DESC">
			</cfif>
		<cfelse>
		    <cfset requestString = requestString & "&ORDERBY=#URLEncodedFormat(headerColumn)#+ASC&SORTORDER=DESC&header=#URLEncodedFormat(attributes.header)#&headerColumns=#URLEncodedFormat(attributes.headerColumns)#&headerTypes=#URLEncodedFormat(thistag.headerTypes)#">
		</cfif>
 		 <a href="javascript:;" onclick="startRequest_range('#requestString#');" onmouseover="window.status='';return true;" alt="Click to sort by #headerText#, double-click to reverse" Title="Click to sort by #headerText#, double-click to reverse">#headerText#</A>
        <cfelse>
           #headerText#		
		</cfif>          
                 
		
      </th>
    </cfloop>
	</cfoutput>
 
  </tr>
  </thead>
  <tbody>
  <!--- loop through the results --->

  <cfoutput query="thistag.result" startrow="#startindex#" MAXROWS="#max_rows#">
       <cfset thistag.numofCol = thistag.numberOfColumns + 1>
       <cfif CurrentRow mod 2 eq 0>
          
          <tr class="tr_even" style="display:none" id="hide#CurrentRow#">
             <td colspan="#thistag.numofCol#">
                 <cfset requestString = "start=#attributes.startindex#&querySearch=#URLEncodedFormat(attributes.query)#&header=#URLEncodedFormat(attributes.header)#&headerColumns=#URLEncodedFormat(attributes.headerColumns)#&headerTypes=#URLEncodedFormat(thistag.headerTypes)#">

             	 <input type="button" class="#attributes.buttonclass#" value="Hide"  onClick="servOC(#CurrentRow#,#attributes.detailpageheight#,#attributes.detailpageincrement#);if (resetQSL == 'true') startRequest_range('#requestString#');">
             </td>
          </tr>

       
          <tr class="tr_even" style="display:none" id="ihtr#CurrentRow#">
            <td colspan="#thistag.numofCol#">
               <table width="100%" cellspacing="0" cellpadding="0" border="0">
                   <tr>
                       <td style="border:3px solid ##003366">
                       <iframe frameborder="0" width="100%" id="ihif#CurrentRow#" name="ihif#CurrentRow#" src="blank.html"></iframe>
                       </td>
                   </tr>
               </table>
            </td>
         </tr>
       
       
          <tr id="qsltr#CurrentRow#" class="tr_even" onmouseover="setScope(this,event,1,#thistag.numberOfColumns# + 1)"
              onmouseout="setScope(this,event,0,#thistag.numberOfColumns# + 1)">

       <cfelse>

          <tr class="tr_odd" style="display:none" id="hide#CurrentRow#">
             <td colspan="#thistag.numofCol#">
				 <cfset requestString = "start=#attributes.startindex#&querySearch=#URLEncodedFormat(attributes.query)#&header=#URLEncodedFormat(attributes.header)#&headerColumns=#URLEncodedFormat(attributes.headerColumns)#&headerTypes=#URLEncodedFormat(thistag.headerTypes)#">
              	 <input type="button" class="#attributes.buttonclass#" value="Hide"  onClick="servOC(#CurrentRow#,#attributes.detailpageheight#,#attributes.detailpageincrement#);if (resetQSL == 'true') startRequest_range('#requestString#');">

              </td>
          </tr>
       
          <tr class="tr_odd" style="display:none" id="ihtr#CurrentRow#">
            <td colspan="#thistag.numofCol#">
               <table width="100%" cellspacing="0" cellpadding="0" border="0">
                   <tr>
                       <td style="border:3px solid ##003366">
                       <iframe frameborder="0" width="100%" id="ihif#CurrentRow#" name="ihif#CurrentRow#" src="blank.html"></iframe>
                       </td>
                   </tr>
               </table>
            </td>
         </tr>
         
          <tr id="qsltr#CurrentRow#" class="tr_odd" onmouseover="setScope(this,event,1,#thistag.numberOfColumns# +1)"
             
              onmouseout="setScope(this,event,0,#thistag.numberOfColumns# + 1)">
                           
       </cfif> 
           
	<td align=center valign="middle" class="Item" id="view#CurrentRow#">
	


 

           <cfif attributes.detailpage neq "">
           <form action="#attributes.detailpage#" target="ihif#CurrentRow#" method="POST" style="margin-top: 0;margin-left: 0; margin-right: 0; margin-bottom: 0;" >

           <input type="hidden" name="QUERY" value="#attributes.query#">
          
           <input type="hidden" name="DETAILKEYVALUE" value="#Evaluate(thistag.keyname)#">
           <input type="hidden" name="DETAILKEYTYPE" value="#attributes.keytype#">
           
             
             <cfif CurrentRow mod 2 eq 0>          
                <input type="hidden" name="rowkind" value="tr_even" />
             <cfelse>
                <input type="hidden" name="rowkind" value="tr_odd" />
             </cfif>
           
     
	       <a name="anchor#CurrentRow#"></a><div id="view#CurrentRow#" class="viewoff"><input type="button" class="#attributes.buttonclass#" id="viewbutton#CurrentRow#" value="View"  onClick="servOC(#CurrentRow#,#attributes.detailpageheight#,#attributes.detailpageincrement#,#thistag.numberOfColumns# + 1); submit();if (#thistag.backcounter_name# == -1) { #thistag.backcounter_name# = -3 } else #thistag.backcounter_name# = #thistag.backcounter_name#-1;window.location.hash='anchor#CurrentRow#'"></div>
              
	      </form>
	      <cfelse>&nbsp;
	      </cfif>
	
	      
          </td>
         
		 <cfif thistag.customtypes eq "true">
		    <cfset thistag.customStruct = StructNew()>
		    <cfloop index="i" from="1" to="#ListLen(attributes.headerColumns)#">
		        <cfif ListGetAt(thistag.headerTypes,i) neq "CUSTOM">
			        <cfset thistag.column = ListGetAt(attributes.headerColumns,i)>
    		        <cfset StructInsert(thistag.customStruct,thistag.column,trim(Evaluate(thistag.column)))>
				</cfif>
		    </cfloop>
		 </cfif>
         
	     <cfloop index="i" from="1" to="#ListLen(attributes.headerColumns)#">
             <cfset thistag.column = ListGetAt(attributes.headerColumns,i)>
             <cfset thistag.type= ListGetAt(thistag.headerTypes,i)>
			 <cfif thistag.type eq "CUSTOM" or thistag.type eq "custom">
			    <td class="Item">
			      <cfif IsDefined('attributes.customcolumn')>
			        <cfset attributes.customcolumn.outputCustomColumn(thistag.column,thistag.customStruct)>
			      <cfelse>
			        &nbsp;
			      </cfif>
			    </td>
			 <cfelse>
               <cfset thistag.val = trim(Evaluate(thistag.column))>
			
			
			   <cfif IsDefined('attributes.mappings')>
                 <cfset thistag.val = attributes.mappings.getBackwardValueMapping(thistag.column,thistag.val)>
               </cfif>
			

                  <cfset thistag.vallength = #Len(thistag.val)#>
                  <cfif (thistag.type eq "DATE" or thistag.type eq "date") AND thistag.val is "01/01/1900" AND thistag.vallength eq 10>
                    <cfset thistag.val = "Unknown Date">
                  <cfelseif (thistag.type eq "TIMESTAMP" or thistag.type eq "timestamp") AND thistag.vallength gte 19 AND Left(thistag.val,19) eq "01/01/1900 00:00:00">
                    <cfset thistag.val = "Unknown Timestamp">
                  <cfelseif (thistag.type eq "TIME" or thistag.type eq "time") AND ((thistag.vallength gte 8 AND Left(thistag.val,8) eq "00:00:00") OR (thistag.vallength gte 7 AND Left(thistag.val,7) eq "0:00:00"))>
                    <cfset thistag.val = "Unknown Time">           		
                  </cfif>  
              
          
               <cfif thistag.val eq "">
                 <cfset thistag.val = "&nbsp;">
               <cfelse>
			
			     <cfif thistag.type eq "DATE" or thistag.type eq "date">
				   <cfset thistag.val = DateFormat(thistag.val,attributes.dateformat)>
			     <cfelseif thistag.type eq "TIME" or thistag.type eq "time">
			       <cfset thistag.val = TimeFormat(thistag.val,attributes.timeformat)>
			     <cfelseif thistag.type eq "TIMESTAMP" or thistag.type eq "timestamp">
			       <cfset thistag.val = DateFormat(thistag.val,attributes.dateformat) &  TimeFormat(thistag.val,attributes.timeformat)>
			     </cfif>
                 <cfset thistag.val = XmlFormat(thistag.val)>
               </cfif> 

<!--- make assumption that if we have a boolean value that we can use a checkbox for display, 
     probably could enforce the use of BOOLEAN type if we wanted to --->
              <td class="Item">
              <cfif thistag.val eq "Y" or thistag.val eq "y" OR thistag.val eq "TRUE" or thistag.val eq "true" or thistag.val eq "True">
                  <center><input type="checkbox" checked readonly></center>
              <cfelseif thistag.val eq "N" or thistag.val eq "n" OR thistag.val eq "FALSE" or thistag.val eq "false" or thistag.val eq "False">
                  <center><input type="checkbox" readonly></center>
              <cfelse> 
                  #thistag.val#
              </cfif>
              </td>
            </cfif>

         </cfloop>
     
            </tr>
      </cfoutput>
</tbody>



<!--- because this is a custom tag this code must be in the tag since it may be in a custom tag directory
        <cfinclude template="QSLheader.cfm">
		--->
  <tfoot>	
  <tr class="tr_header">
    <th class="th_even">             

       <cfif thistag.result.RecordCount gt MAX_ROWS>
           <cfset pad = 0>
           <cfif STARTINDEX gt 1>
             <cfset pad = #Len(MAX_ROWS)#>
           </cfif>
		
		   <cfset pad = Len(thistag.result.RecordCount)>
           <cfif STARTINDEX gt 1>
               
               <cfset to = STARTINDEX - 1>
               <cfset from = STARTINDEX - MAX_ROWS>
               <cfset padstring = MAX_ROWS>
               <cfset len = pad - Len(MAX_ROWS)>
               <cfoutput>
               <cfloop index="i" from="1" to="#len#">
                   <cfset padstring = "0#padstring#">
               </cfloop>
               <cfset next = "Prev #padstring#">
               
               <cfset requestString = "start=#from#&querySearch=#URLEncodedFormat(attributes.query)#&header=#URLEncodedFormat(attributes.header)#&headerColumns=#URLEncodedFormat(attributes.headerColumns)#&headerTypes=#URLEncodedFormat(thistag.headerTypes)#">
 
                <form action="##" method="GET" style="margin-top: 0;margin-left: 0; margin-right: 0; margin-bottom: 0;">
                     <input type="button" class="#attributes.buttonclass#" value="#next#" onclick="startRequest_range('#requestString#');">                   
                </form>           
               </cfoutput>        
           </cfif>
           <cfset from = STARTINDEX+MAX_ROWS>
           <cfif from lte thistag.result.RecordCount>
              
               <cfset to = STARTINDEX + MAX_ROWS + MAX_ROWS>
               <cfif to gt thistag.result.RecordCount>
                  <cfset to = thistag.result.RecordCount+1>
               </cfif>
               <cfset padstring = to-(STARTINDEX+MAX_ROWS)>
               <cfset len = pad - Len(to-(STARTINDEX+MAX_ROWS))>
               <cfoutput>
               <cfloop index="i" from="1" to="#len#">
                   <cfset padstring = "0#padstring#">
               </cfloop>
               <cfset next = "Next #padstring#">
               <cfset requestString = "start=#from#&querySearch=#URLEncodedFormat(attributes.query)#&header=#URLEncodedFormat(attributes.header)#&headerColumns=#URLEncodedFormat(attributes.headerColumns)#&headerTypes=#URLEncodedFormat(thistag.headerTypes)#">
                 <form action="##" method="GET" style="margin-top: 0;margin-left: 0; margin-right: 0; margin-bottom: 0;">
 
                     <input type="button" class="#attributes.buttonclass#" value="#next#" onclick="startRequest_range('#requestString#');">
                   
                </form>
             
              </cfoutput>
           </cfif>
        
      <cfelse>
    
        &nbsp;
      </cfif>
    </th> 

    <cfoutput>
    <cfloop index="column" from="1" to="#ListLen(attributes.header)#">
		
      <cfset headerColumn = ListGetAt(attributes.headerColumns,column)> 
	  <cfset headerText = ListGetAt(attributes.header,column)>
      <th nowrap class="th_even">
        <cfif attributes.allowsorting eq "true">
         <cfset requestString = "start=#1#&querySearch=#URLEncodedFormat(attributes.query)#">
 		 <cfif IsDefined('Attributes.SORTORDER')>
	        <cfset requestString = requestString & "&ORDERBY=#URLEncodedFormat(headerColumn)#+#Attributes.SORTORDER#&header=#URLEncodedFormat(attributes.header)#&headerColumns=#URLEncodedFormat(attributes.headerColumns)#&headerTypes=#URLEncodedFormat(thistag.headerTypes)#">
   
		    <cfif Attributes.SORTORDER eq "DESC">
			    <cfset requestString = requestString & "&SORTORDER=ASC">
			<cfelse>
			    <cfset requestString = requestString & "&SORTORDER=DESC">
			</cfif>
		<cfelse>
		    <cfset requestString = requestString & "&ORDERBY=#URLEncodedFormat(headerColumn)#+ASC&SORTORDER=DESC&header=#URLEncodedFormat(attributes.header)#&headerColumns=#URLEncodedFormat(attributes.headerColumns)#&headerTypes=#URLEncodedFormat(thistag.headerTypes)#">
		</cfif>
 		 <a href="javascript:;" onclick="startRequest_range('#requestString#');" onmouseover="window.status='';return true;" alt="Click to sort by #headerText#, double-click to reverse" Title="Click to sort by #headerText#, double-click to reverse">#headerText#</A>
        <cfelse>
           #headerText#		
		</cfif>                  
                 
		
      </th>
    </cfloop>
	</cfoutput>
 
  </tr>		
  </tfoot>

</table>
</div>
</fieldset>

<cfif thistag.result.RecordCount eq 1>
   <script type="text/javascript">

     document.getElementById('viewbutton1').click();
   </script>
</cfif>