# Deck Email Templates

This folder contains **HTML templates** used for email rendering.

## How to Add or Edit Templates

1. **Create or Edit the HTML File**
   - Store your HTML file in the appropriate subfolder.
   - Follow the naming convention (e.g., `33-en.html` for English, `33-pt.html` for Portuguese).

2. **Update the Template Mappings**
   - Open [`src/lib/templates.ts`](../../src/lib/templates.ts).
   - Set the template mapping from your **enum key** to the template path.
   - Set the variable keys that exist

   **Example:**

   ```ts
   export const templateHumanReadableNames: Record<EmailTemplate, string> = {
     [EmailTemplate.COMPANIES_EN]: "Companies Invitation - English",
     [EmailTemplate.COMPANIES_PT]: "Companies Invitation - Portuguese",
   };

   export const templatePaths: Record<EmailTemplate, string> = {
     [EmailTemplate.COMPANIES_EN]: "/companies/32-en.html",
     [EmailTemplate.COMPANIES_PT]: "/companies/32-pt.html",
   };

   export const templateVariablesKeys: Record<
     EmailTemplate,
     Pick<EmailVariable, "key">[]
   > = {
     [EmailTemplate.COMPANIES_EN]: [
       { key: EmailVariableKey.Edition },
       { key: EmailVariableKey.EditionOrdinal },
       { key: EmailVariableKey.Company },
       { key: EmailVariableKey.EventStartFormat },
       { key: EmailVariableKey.EventEndFormat },
     ],
     [EmailTemplate.COMPANIES_PT]: [
       { key: EmailVariableKey.Edition },
       { key: EmailVariableKey.EditionOrdinal },
       { key: EmailVariableKey.Company },
       { key: EmailVariableKey.EventStartFormat },
       { key: EmailVariableKey.EventEndFormat },
     ],
   };
   ```

## New variables
