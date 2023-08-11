*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.FileSystem
Library             RPA.RobotLogListener


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${order}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${order}
    END
    Create ZIP package
    Close the robot order website


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${files}=    Read table from CSV    orders.csv    header=True
    RETURN    ${files}

Close the annoying modal
    Click Button    OK

Fill the form
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    class:form-control    ${order}[Legs]
    Input Text    address    ${order}[Address]
    Click Button    Preview
    # Mute Run On Failure    Click the Order Button
    Wait Until Keyword Succeeds    10x    0.01 sec    Click the Order Button

    ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]
    ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
    Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
    Click Button    Order another robot

Click the Order Button
    Click Button    Order
    Wait Until Page Contains Element    id:receipt

Store the receipt as a PDF file
    [Arguments]    ${ordernr}
    ${order_results_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${order_results_html}    ${OUTPUT_DIR}${/}orders${/}${ordernr}_order_results.pdf
    RETURN    ${OUTPUT_DIR}${/}orders${/}${ordernr}_order_results.pdf

Take a screenshot of the robot
    [Arguments]    ${ordernr}
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}pictures${/}${ordernr}_order_picture.png
    RETURN    ${OUTPUT_DIR}${/}pictures${/}${ordernr}_order_picture.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    ${files}=    Create List    ${screenshot}
    Add Files To Pdf    ${files}    ${pdf}    append=True
    Close Pdf
    Remove Directory    ${OUTPUT_DIR}${/}pictures    True

Create ZIP package
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}${/}PDFs.zip
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}${/}orders
    ...    ${zip_file_name}
    Remove Directory    ${OUTPUT_DIR}${/}orders    True

Close the robot order website
    Close Browser
