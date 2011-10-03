#import "tuneup/tuneup.js"

var target = UIATarget.localTarget();
var app = target.frontMostApp();

target.delay(1);
test('Checking the Log View', function(app, target)
{
    assertWindow(
    {
        navigationBar:
        {
            name: 'Glucose',
//            leftButton: { name: 'Settings' },
//            rightButton: { name: 'Add' },
        },
        tableViews:
        [{
            groups: [{name: 'Today'}],  // Only one section
            cells: [],  // TableView must be empty at this point
        }],
    });
});

// Tap on the settings button and check the Settings view
app.mainWindow().navigationBar().buttons()[0].tap();
target.delay(1);

test('Checking the Settings View', function(app, target)
{
    assertWindow(
    {
        navigationBar:
        {
            name: 'Settings',
            rightButton: { name: 'Done' },
        },
        tableViews:
        [{
            groups:
            [
                { name: 'Glucose v0.7.1'},
                { name: 'Copyright 2008-2011 Brandon Fosdick' },
            ],
            cells:
            [
                { name: 'Export' },
                { name: 'Purge'  },
                { name: 'Categories' },
                { name: 'Insulin Types' },
                { name: 'Insulins for New Entries' },
                { name: 'Fractional Insulin' },
                { name: 'Glucose Units' },
                { name: 'High Glucose Warning' },
                { name: 'Low Glucose Warning' },
                { name: 'Write a Review' },
                { name: 'More Information' },
                { name: 'Report a Bug' },
            ]
        }],
    });
});

// Tap on Categories and check the Categories view
app.mainWindow().tableViews()[0].cells()['Categories'].tap();
target.delay(1);

test('Checking the Settings > Categories View', function(app, target)
{
    assertWindow(
    {
        navigationBar:
        {
            name: 'Categories',
            leftButton: { name: 'Settings' },
            rightButton: { name: 'Add' },
        },
        tableViews:
        [{
            groups:
            [
                { name: 'Add, delete, rename or reorder categories'},
            ],
            cells:
            [
                {   name: 'Breakfast', 
                    switches: [{name: 'Delete Breakfast'}],
                    buttons: [{name: 'Reorder Breakfast'}]
                },
                {   name: 'Lunch',
                    switches: [{name: 'Delete Lunch'}],
                    buttons: [{name: 'Reorder Lunch'}]
                },
                {   name: 'Dinner',
                    switches: [{name: 'Delete Dinner'}],
                    buttons: [{name: 'Reorder Dinner'}]
                },
                {   name: 'Exercise',
                    switches: [{name: 'Delete Exercise'}],
                    buttons: [{name: 'Reorder Exercise'}]
                },
                {   name: 'After Breakfast',
                    switches: [{name: 'Delete After Breakfast'}],
                    buttons: [{name: 'Reorder After Breakfast'}]
                },
                {   name: 'After Lunch',
                    switches: [{name: 'Delete After Lunch'}],
                    buttons: [{name: 'Reorder After Lunch'}]
                },
                {   name: 'After Dinner',
                    switches: [{name: 'Delete After Dinner'}],
                    buttons: [{name: 'Reorder After Dinner'}]
                },
                {   name: 'After Exercise',
                    switches: [{name: 'Delete After Exercise'}],
                    buttons: [{name: 'Reorder After Exercise'}]
                },
                {   name: 'Bedtime',
                    switches: [{name: 'Delete Bedtime'}],
                    buttons: [{name: 'Reorder Bedtime'}]
                },
                {   name: 'Restore Default Categories' },
            ]
        }],
    });
});

// Return the settings view
app.mainWindow().navigationBar().leftButton().tap();
target.delay(1);

// Test the Insulin Types view
app.mainWindow().tableViews()[0].cells()['Insulin Types'].tap();
target.delay(1);

test('Checking the Settings > Insulin Types View', function(app, target)
{
    assertWindow(
    {
        navigationBar:
        {
            name: 'Insulin Types',
            leftButton: { name: 'Settings' },
            rightButton: { name: 'Add' },
        },
        tableViews:
        [{
            groups:
            [
                { name: 'Add, delete, rename or reorder insulin types'},
            ],
            cells:
            [
                {   name: 'Aspart', 
                    switches: [{name: 'Delete Aspart'}],
                    buttons: [{name: 'Reorder Aspart'}]
                },
                {   name: 'Detemir',
                    switches: [{name: 'Delete Detemir'}],
                    buttons: [{name: 'Reorder Detemir'}]
                },
                {   name: 'Glargine',
                    switches: [{name: 'Delete Glargine'}],
                    buttons: [{name: 'Reorder Glargine'}]
                },
                {   name: 'Glulisine',
                    switches: [{name: 'Delete Glulisine'}],
                    buttons: [{name: 'Reorder Glulisine'}]
                },
                {   name: 'Lispro',
                    switches: [{name: 'Delete Lispro'}],
                    buttons: [{name: 'Reorder Lispro'}]
                },
                {   name: 'NPH',
                    switches: [{name: 'Delete NPH'}],
                    buttons: [{name: 'Reorder NPH'}]
                },
                {   name: 'Regular',
                    switches: [{name: 'Delete Regular'}],
                    buttons: [{name: 'Reorder Regular'}]
                },
                {   name: 'Lente',
                    switches: [{name: 'Delete Lente'}],
                    buttons: [{name: 'Reorder Lente'}]
                },
                {   name: 'UltraLente',
                    switches: [{name: 'Delete UltraLente'}],
                    buttons: [{name: 'Reorder UltraLente'}]
                },
                {   name: '70/30',
                    switches: [{name: 'Delete 70/30'}],
                    buttons: [{name: 'Reorder 70/30'}]
                },
                {   name: '50/50',
                    switches: [{name: 'Delete 50/50'}],
                    buttons: [{name: 'Reorder 50/50'}]
                },
                {   name: 'Restore Default Types' },
            ]
        }],
    });
});

// Return the settings view
app.mainWindow().navigationBar().leftButton().tap();
target.delay(1);

// Test the 'Insulins for New Entries' view
app.mainWindow().tableViews()[0].cells()['Insulins for New Entries'].tap();
target.delay(1);

test('Checking the Settings > Insulins for New Entries View', function(app, target)
{
    assertWindow(
    {
        navigationBar:
        {
            name: 'Default Insulin Types',
            leftButton: { name: 'Settings' },
        },
        tableViews:
        [{
            groups:
            [
                { name: 'Choose up to 2 insulin types to be automatically added to new log entries'},
            ],
            cells:
            [
                { name: 'Aspart', value: 1 },
                { name: 'Detemir' },
                { name: 'Glargine' },
                { name: 'Glulisine' },
                { name: 'Lispro' },
                { name: 'NPH', value: 1 },
                { name: 'Regular' },
                { name: 'Lente' },
                { name: 'UltraLente' },
                { name: '70/30' },
                { name: '50/50' },
            ]
        }],
    });
});

// Return the settings view
app.mainWindow().navigationBar().leftButton().tap();
target.delay(1);

// Return to Log View
app.mainWindow().navigationBar().rightButton().tap();
