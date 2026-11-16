// Site-wide switches. Change a value, rebuild, deploy.

/**
 * The privacy notice (/privacy/) is a DRAFT until Zee approves it (PRIVACY_DRAFT.md).
 * While false: the page is not built, it is not in sitemap.xml, and the footer link is hidden.
 * Set to true only once every [ZEE TO CONFIRM] marker in the page is resolved:
 * scripts/check-privacy-gate.sh (run by scripts/deploy.sh) refuses a deploy otherwise.
 * Keep this line exactly in the form `export const PRIVACY_NOTICE_LIVE = true|false;`
 * because the gate script reads it.
 */
export const PRIVACY_NOTICE_LIVE = false;
