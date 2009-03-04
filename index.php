<?php
	include_once '/home/bfoz/public_html/include/common.php';
?>
<html>
	<head>
		<title>Glucose</title>
		<link rel="stylesheet" href="/style.css" type="text/css" />
	</head>

	<body>
		<div id='LinkBar'>
			<?php EmitLinkbar(); ?>
		</div>
		<div style="text-align:center">
			<h1>Glucose</h1>
			<img src="./screenshots/release_0.6/main.jpg">
			<img src="./screenshots/release_0.6/newentry.jpg">
		</div>
		<div id="content">
			<p>Glucose is an iPhone application that aids diabetics in monitoring and recording glucose measurements.</p>
			<p>Glucose is meant to be a convenient and simple tool for helping diabetics record blood glucose measurements and insulin usage. It's built on the principle of doing one thing and doing it well, and should have everything needed for day to day use. If you find that a frequently needed feature is missing, please let me know.</p>
			<p><strong>NOTE</strong>: Insulin is marketed under various brand names around the world. Instead of trying to keep track of the various brands for different regions, Glucose simply uses the scientific name for each insulin type. For example, if you're using <a href="http://www.novonordisk.com/">Novo Nordisk</a>'s <a href="http://www.novolog.com/">Novolog</a> branded <a href="http://en.wikipedia.org/wiki/Insulin_aspart">Insulin Aspart</a>, you'll choose Aspart in the insulin types list. If you're not sure of the proper name for the insulin you use look on the packaging or contact your doctor or pharmacist.</p>
			<h2>Features</h2>
			<ul>
				<li>Log glucose readings and Insulin dosage</li>
				<li>Support for mg/dL and mmol/L</li>
				<li>Export to Google Docs Spreadsheets</li>
				<li>Automatically share exported data with a list of contacts</li>
				<li>Support for fractional insulin doses</li>
				<li>Customizable Categories and Insulin types</li>
				<li>Color-coded display of high/low readings</li>
			</ul>

			<h2>To Do</h2>
			<ul>
				<li>Import records </li>
				<li>Predictive entry</li>
				<li>Statistics and plotting</li>
				<li>Synchronize with a personal server</li>
			</ul>

			<h2>Download</h2>
			<p>Starting with version 0.3, Glucose is only available through the App Store. I'll send future Beta releases directly to participants.</p>
			<ul>
				<li><a href="http://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=294296711&mt=8">Glucose (latest)</a></li>
				<li><a href="./release/glucose_0.2.zip">Beta 2 (v0.2)</a></li>
				<li><a href="./release/GlucoseBeta1.zip">Beta 1 (v0.1)</a></li>
			</ul>

			<h2>Installation</h2>
			<p>Use the <a href="http://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=294296711&mt=8">iTunes App Store</a></p>

			<h2>Support / Mailing lists</h2>
			<table style="margin-left:2em">
				<tr><td><a href="http://lists.bfoz.net/mailman/listinfo/glucose-announce">glucose-announce</a></td><td>Announcements (very low volume)</td></tr>
				<tr><td><a href="http://lists.bfoz.net/mailman/listinfo/glucose-users">glucose-users</a></td><td>Users mailing list</td></tr>
			</table>

			<h2>License</h2>
			<p>Glucose is Copyright 2008-2009 by <a href="mailto:bfoz@bfoz.net">Brandon Fosdick</a>.</p>

			<h2>History</h2>
			<p><a href="http://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=294296711&mt=8">Version 0.6.1</a> - Released March 3, 2009
				<ul>
					<li>Fixed crash when creating an entry with a timestamp in the past</li>
					<li>Glucose values are color coded on the entry detail view</li>
				</ul>
			</p>
			<p><a href="http://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=294296711&mt=8">Version 0.6</a> - Released February 10, 2009
				<ul>
					<li>Support for sharing exported files with a list of contacts</li>
					<li>Exports to Google Docs are now uploaded to the 'Glucose Export' folder</li>
					<li>Switched to "cash-register" style input for fractional values in mmol/L mode</li>
					<li>Support for fractional insulin doses. Enabled with the "Fractional Insulin" switch on the Settings screen.</li>
					<li>Google Data client library version 1.6</li>
					<li>Requires iPhone OS 2.2 or later (fixes a few layout issues)</li>
					<li>Deleting an in-use category displays a warning and requires user confirmation</li>
					<li>Deleting an in-use insulin type displays a warning and requires user confirmation</li>
					<li>New-entry default insulin selection is now saved properly</li>
					<li>Glucose values are properly colored in mmol/L mode</li>
					<li>Export date range is now saved properly</li>
				</ul>
			</p>
			<p><a href="http://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=294296711&mt=8">Version 0.5</a> - Released December 7, 2008
				<ul>
					<li>Performance improvements for large datasets</li>
					<li>Display correct keyboard for glucose threshold fields in mmol/L mode</li>
					<li>Added 'Exercise' and 'After Exercise' to default categories for new installs</li>
					<li>Fix glucose color-coding on Log view</li>
					<li>Fix crash-on-restart that occurs after deleting insulin types that are on the default type list</li>
					<li>Better handling of single-dose log entries</li>
					<li>Deleting an insulin type deletes all doses of that type</li>
					<li>Deleting a category deletes all log entries in the category</li>
				</ul>
			</p>
			<p><a href="http://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=294296711&mt=8">Version 0.4</a> - Released November 3, 2008
				<ul>
					<li>Support for mmol/L (Settings screen)</li>
					<li>Tap anywhere on glucose threshold rows to edit (Settings screen)</li>
					<li>Display note-only records on the main log view</li>
					<li>Configuring default insulin types for new records should be more intuitive now</li>
					<li>Fixed a few minor display bugs</li>
					<li>Google Data client library version 1.5</li>
				</ul>
			</p>
			<p><a href="http://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=294296711&mt=8">Version 0.3</a> - Released October 24, 2008
				<ul>
					<li>First version submitted to the App Store</li>
					<li>Bug fixes and cleanups</li>
				</ul>
			</p>
			<p><a href="./release/glucose_0.2.zip">Version 0.2</a> - Released October 12, 2008
				<ul>
					<li>Export to Google Spreadsheets</li>
					<li>Purge old records</li>
					<li>Color glucose measurements according to high/low thresholds</li>
				</ul>
			</p>
			<p><a href="./release/GlucoseBeta1.zip">Version 0.1</a> - Released September 01, 2008
				<ul>
					<li>First beta release to <a href="http://arstechnica.com">Ars Technica</a>'s <a href="http://episteme.arstechnica.com/eve/forums/a/tpc/f/8300945231/m/530009424931?r=889002994931#889002994931"> Macintoshian Achaia forum</a></li>
					<li>Usable, but lots of rough edges</li>
				</ul>
			</p>
		</div>	<!-- id='content' -->
	</body>
</html>
