import { defineConfig } from "eslint/config";
import { sldsCssPlugin } from "@salesforce-ux/eslint-plugin-slds";

// Salesforce Developers: SLDS Linter: Rules
// https://developer.salesforce.com/docs/platform/slds-linter/guide/reference-rules.html

export default defineConfig([
  {
    plugins: {
      ...sldsCssPlugin()
    },
    extends: ["@salesforce-ux/slds/recommended"],
    rules: {
        "@salesforce-ux/slds/no-slds-class-overrides": "warn", // 24 warnings remaining...
        "@salesforce-ux/slds/no-deprecated-slds-classes": "error",
        "@salesforce-ux/slds/lwc-token-to-slds-hook": "error",
        "@salesforce-ux/slds/enforce-sds-to-slds-hooks": "error",
        "@salesforce-ux/slds/no-sldshook-fallback-for-lwctoken": "error",
        "@salesforce-ux/slds/no-unsupported-hooks-slds2": "error",
        "@salesforce-ux/slds/no-slds-var-without-fallback": "error",
        "@salesforce-ux/slds/no-slds-namespace-for-custom-hooks": "error",
        "@salesforce-ux/slds/enforce-component-hook-naming-convention": "error",
        "@salesforce-ux/slds/no-slds-private-var": "error",
        "@salesforce-ux/slds/no-hardcoded-values-slds2": "warn", // 80 warnings remaining...
        "@salesforce-ux/slds/reduce-annotations": "error",
        "@salesforce-ux/slds/enforce-bem-usage": "error",
        "@salesforce-ux/slds/no-deprecated-classes-slds2": "error",
        "@salesforce-ux/slds/modal-close-button-issue": "error"
    }
  },
]);
