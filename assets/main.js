//Chart Data
var template_vars = []
var data1 = {
	datasets : [
		{
			fillColor : "rgba(133,215,224,0.5)",
			strokeColor : "rgba(133,215,224,1)",
			pointColor : "rgba(133,215,224,1)",
			pointStrokeColor : "#fff",
		},
		{
			fillColor : "rgba(194,224,133,0.5)",
			strokeColor : "rgba(194,224,133,1)",
			pointColor : "rgba(194,224,133,1)",
			pointStrokeColor : "#fff",
		}
	]
};
var options1 = {scaleOverride: true, scaleSteps : 10, scaleStepWidth: 5, scaleStartValue: 0, scaleShowLabels: true, pointDot: false, animationSteps: 120, datasetStrokeWidth: 3, scaleShowGridLines:false};

var data2 = [];
var options2 = {animateScale: true, animationSteps: 200}

var data3 = {
	datasets : [
		{
			fillColor : "rgba(51,189,204,0.5)",
			strokeColor : "rgba(51,189,204,1)",
		}
	]
}
var options3 = {scaleOverride: true, scaleSteps: 4, scaleStepWidth: 3, scaleStartValue: 0, scaleShowLabels: true}

// Insert template variables
function run() {
	for(key in template_vars) {
		$('#' + key).html( template_vars[key] );
	}

	loadChart1();
	loadChart2();
	loadChart3();
}

function loadChart1() {
	//Get the context of the canvas element we want to select
	var ctx = $("#chart1")[0].getContext("2d");
	var chart = new Chart(ctx).Line(data1, options1);
}

function loadChart2() {
	//Get the context of the canvas element we want to select
	var ctx = $("#chart2")[0].getContext("2d");
	var chart = new Chart(ctx).PolarArea(data2, options2);
}

function loadChart3() {
	//Get the context of the canvas element we want to select
	var ctx = $("#chart3")[0].getContext("2d");
	var chart = new Chart(ctx).Bar(data3, options3);
}