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


*** Variables ***

${site_url}     https://robotsparebinindustries.com/#/robot-order
${csv_url}      https://robotsparebinindustries.com/orders.csv


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    # Close the annoying modal
    ${orders}=    Get orders
    FOR    ${order}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${order}
        Wait Until Keyword Succeeds    10x    0.5s    Preview the robot
        Wait Until Keyword Succeeds    10x    0.5s    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Archive output Pdf
    [Teardown]    Close RobotSpareBin Browser


*** Keywords ***
Open the robot order website
    Open Available Browser    ${site_url}    maximized=True

Get orders
    Download    ${csv_url}    ${TEMP_DIR}${/}orders.csv    overwrite=True
    ${orders}=    Read table from CSV    ${TEMP_DIR}${/}orders.csv
    # Log    Found columns: ${orders.columns}
    RETURN    ${orders}

Close the annoying modal
    Wait Until Element Is Visible    //button[contains(.,'OK') and @class="btn btn-dark"]
    Click Button    //button[contains(.,'OK') and @class="btn btn-dark"]

Fill the form
    [Arguments]    ${row}
    Wait Until Element Is Visible    id:head
    Select From List By Value    id:head    ${row}[Head]
    Click Element    xpath=//input[@id="id-body-${row}[Body]"]
    Input Text    xpath=//input[@placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    xpath=//input[@id="address"]    ${row}[Address]

Preview the robot
    Click Element    id:preview
    Wait Until Element Is Visible    xpath=//img[@alt="Head"]
    Wait Until Element Is Visible    xpath=//img[@alt="Body"]
    Wait Until Element Is Visible    xpath=//img[@alt="Legs"]

Submit the order
    Click Element    id:order
    Wait Until Element Is Visible    id:order-completion    0.5s

Go to order another robot
    # Wait Until Element Is Visible    id:order-another
    Click Element    id:order-another

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    ${pdf_path}=    Convert To String    ${OUTPUT_DIR}${/}receipts${/}order_${order_number}.pdf
    Html To Pdf    ${receipt_html}    ${pdf_path}
    RETURN    ${pdf_path}

Take a screenshot of the robot
    [Arguments]    ${order_number}
    ${img_path}=    Set Variable    ${OUTPUT_DIR}${/}images${/}robot_image_${order_number}.png
    Screenshot    css:div#robot-preview-image    ${img_path}
    RETURN    ${img_path}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${files}=    Create List    ${screenshot}:align=center
    Open Pdf    ${pdf}
    Add Files To Pdf    ${files}    ${pdf}    append:${True}
    Close Pdf    ${pdf}

Archive output Pdf
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/orders.zip
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}${/}receipts
    ...    ${zip_file_name}

Close RobotSpareBin Browser
    Empty Directory    ${OUTPUT_DIR}${/}receipts
    Empty Directory    ${OUTPUT_DIR}${/}images
    Close Browser
