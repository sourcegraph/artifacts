-- Document Code
INSERT INTO prompts (name, description, definition_text, mode, builtin, auto_submit, visibility_secret, created_at, updated_at, tenant_id)
SELECT
    'document-code' as name,
    'Document the code in a file' as description,
    'Write a brief documentation comment for  cody://selection. If documentation comments exist in  cody://current-file, or other files with the same file extension, use them as examples. Pay attention to the scope of the selected code (e.g. exported function/API vs implementation detail in a function), and use the idiomatic style for that type of code scope. Only generate the documentation for the selected code, do not generate the code. Do not enclose any other code or comments besides the documentation. Enclose only the documentation for cody://current-selection and nothing else. ' as definition_text,
    'INSERT' as mode,
    't' as builtin,
    't' as auto_submit,
    'f' as visibility_secret,
    '2024-11-20 10:51:36.752627+00',
    '2024-11-20 10:51:36.752627+00',
    tenants.id AS tenant_id
FROM tenants
 ON CONFLICT DO NOTHING;

-- Explain Code
INSERT INTO prompts (name, description, definition_text, mode, builtin, auto_submit, visibility_secret, created_at, updated_at, tenant_id)
SELECT
    'explain-code' as name,
    'Explain the code in a file' as description,
    'Explain what cody://selection code does in simple terms. Assume the audience is a beginner programmer who has just learned the language features and basic syntax. Focus on explaining: 1) The purpose of the code 2) What input(s) it takes 3) What output(s) it produces 4) How it achieves its purpose through the logic and algorithm. 5) Any important logic flows or data transformations happening. Use simple language a beginner could understand. Include enough detail to give a full picture of what the code aims to accomplish without getting too technical. Format the explanation in coherent paragraphs, using proper punctuation and grammar. Write the explanation assuming no prior context about the code is known. Do not make assumptions about variables or functions not shown in the shared code. Start the answer with the name of the code that is being explained.' as definition_text,
    'CHAT' as mode,
    't' as builtin,
    't' as auto_submit,
    'f' as visibility_secret,
    '2024-11-20 10:51:36.752627+00',
    '2024-11-20 10:51:36.752627+00',
    tenants.id AS tenant_id
FROM tenants
ON CONFLICT DO NOTHING;

-- Generate Unit Tests
INSERT INTO prompts (name, description, definition_text, mode, builtin, auto_submit, visibility_secret, created_at, updated_at, tenant_id)
SELECT
    'generate-unit-tests' as name,
    'Generate unit tests the code in a file' as description,
    'Review the shared context and configurations to identify the test framework and libraries in use. Then, generate a suite of multiple unit tests for the functions in cody://selection using the detected test framework and libraries. Be sure to import the function being tested. Follow the same patterns as any shared context. Only add packages, imports, dependencies, and assertions if they are used in cody://current-dir . Pay attention to the file path of each shared context to see if test for cody://current-file already exists. If one exists, focus on generating new unit tests for uncovered cases. If none are detected, import common unit test libraries for cody://current-file. Focus on validating key functionality with simple and complete assertions. Only include mocks if one is detected in cody://current-dir . Before writing the tests, identify which test libraries and frameworks to import, e.g. "No new imports needed - using existing libs" or "Importing test framework that matches shared context usage" or "Importing the defined framework", etc. Then briefly summarize test coverage and any limitations. At the end, enclose the full completed code for the new unit tests, including all necessary imports, in a single markdown codeblock. No fragments or TODO. The new tests should validate expected functionality and cover edge cases for cody://selection with all required imports, including importing the function being tested. Do not repeat existing tests.' as definition_text,
    'CHAT' as mode,
    't' as builtin,
    't' as auto_submit,
    'f' as visibility_secret,
    '2024-11-20 10:51:36.752627+00',
    '2024-11-20 10:51:36.752627+00',
    tenants.id AS tenant_id
FROM tenants
ON CONFLICT DO NOTHING;

-- Find Code Smells
INSERT INTO prompts (name, description, definition_text, mode, builtin, auto_submit, visibility_secret, created_at, updated_at, tenant_id)
SELECT
    'find-code-smells' as name,
    'Review and analyze code' as description,
    'Please review and analyze the cody://selection and identify potential areas for improvement related to code smells, readability, maintainability, performance, security, etc. Do not list issues already addressed in the given code. Focus on providing up to 5 constructive suggestions that could make the code more robust, efficient, or align with best practices. For each suggestion, provide a brief explanation of the potential benefits. After listing any recommendations, summarize if you found notable opportunities to enhance the code quality overall or if the code generally follows sound design principles. If no issues found, reply "There are no errors."' as definition_text,
    'CHAT' as mode,
    't' as builtin,
    't' as auto_submit,
    'f' as visibility_secret,
    '2024-11-20 10:51:36.752627+00',
    '2024-11-20 10:51:36.752627+00',
    tenants.id AS tenant_id
FROM tenants
ON CONFLICT DO NOTHING;
