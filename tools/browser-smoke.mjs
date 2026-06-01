#!/usr/bin/env node

import fs from 'node:fs/promises';
import path from 'node:path';
import { createRequire } from 'node:module';

const require = createRequire(process.env.RAPID_APEX_PLAYWRIGHT_REQUIRE || import.meta.url);
const { chromium } = require('playwright');

function parseArgs(argv) {
  const args = {};
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (!arg.startsWith('--')) {
      throw new Error(`Unexpected argument: ${arg}`);
    }
    const key = arg.slice(2);
    const value = argv[i + 1];
    if (!value || value.startsWith('--')) {
      throw new Error(`Missing value for ${arg}`);
    }
    args[key] = value;
    i += 1;
  }
  return args;
}

function requireArg(args, key) {
  if (!args[key]) {
    throw new Error(`Missing required option: --${key}`);
  }
  return args[key];
}

function slugify(value) {
  return value
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function apexSessionFromUrl(url) {
  const friendlyMatch = url.match(/[?&]session=(\d+)/i);
  if (friendlyMatch) {
    return friendlyMatch[1];
  }
  const match = url.match(/f\?p=\d+:\d+:(\d+)/i);
  return match ? match[1] : '';
}

async function apexSessionFromPage(page) {
  const pInstance = page.locator('#pInstance').first();
  if (await pInstance.count()) {
    const value = await pInstance.inputValue().catch(() => '');
    if (value) {
      return value;
    }
  }

  const hrefs = await page.locator('a').evaluateAll((links) => links.map((link) => link.href || ''));
  for (const href of hrefs) {
    const session = apexSessionFromUrl(href);
    if (session) {
      return session;
    }
  }
  return '';
}

async function visibleLocator(page, selectors) {
  for (const selector of selectors) {
    await page.waitForSelector(selector, { state: 'attached', timeout: 3000 }).catch(() => {});
    const locator = page.locator(selector);
    const count = await locator.count();
    for (let i = 0; i < count; i += 1) {
      const candidate = locator.nth(i);
      try {
        await candidate.waitFor({ state: 'visible', timeout: 1000 });
        return candidate;
      } catch {
        // Try the next matching element or selector.
      }
    }
  }
  throw new Error(`None of these selectors became visible: ${selectors.join(', ')}`);
}

async function fillFirst(page, selectors, value) {
  const locator = await visibleLocator(page, selectors);
  await locator.fill(value);
}

async function clickFirst(page, selectors) {
  const locator = await visibleLocator(page, selectors);
  await Promise.all([
    page.waitForLoadState('domcontentloaded').catch(() => {}),
    locator.click(),
  ]);
}

async function waitForApexSubmit(page) {
  await page.waitForFunction(() => window.apex && typeof window.apex.submit === 'function', null, { timeout: 30000 }).catch(() => {});
}

async function waitForCreateApplicationEnabled(page) {
  const appName = page.locator('#P1_APP_NAME, #P56_APP_NAME, input[name="P1_APP_NAME"], input[name="P56_APP_NAME"]').first();
  if (await appName.count()) {
    await appName.evaluate((element) => {
      element.dispatchEvent(new Event('input', { bubbles: true }));
      element.dispatchEvent(new KeyboardEvent('keyup', { bubbles: true, key: 'A' }));
      element.dispatchEvent(new Event('change', { bubbles: true }));
      element.blur();
    }).catch(() => {});
  }
  return page.waitForFunction(() => {
    const button = document.querySelector('#CREATE_APP');
    return !button || !button.disabled;
  }, null, { timeout: 10000 })
    .then(() => true)
    .catch(() => false);
}

async function submitCreateApplication(page) {
  if (await waitForCreateApplicationEnabled(page)) {
    await clickFirst(page, [
      '#CREATE_APP',
      'button:has-text("Create Application")',
      'a:has-text("Create Application")',
      'button:has-text("Create App")',
      'a:has-text("Create App")',
      'button:has-text("Create")',
      'a:has-text("Create")',
    ]);
    return;
  }

  await page.evaluate(() => {
    if (window.apex && typeof window.apex.submit === 'function') {
      window.apex.submit({ request: 'CREATE_APP', showWait: true });
      return;
    }
    const form = document.querySelector('#wwvFlowForm');
    if (form) {
      form.submit();
    }
  });
}

async function waitForApplicationCreationComplete(page) {
  const createPageUrl = page.url();
  const completed = await page.waitForFunction(() => {
    const status = document.querySelector('#P1_STATUS')?.value || document.querySelector('#P56_STATUS')?.value || '';
    return ['DONE', 'ERROR', 'ORA_ERROR'].includes(status);
  }, null, { timeout: 600000 })
    .then(() => true)
    .catch(() => false);

  const status = await page.evaluate(() => document.querySelector('#P1_STATUS')?.value || document.querySelector('#P56_STATUS')?.value || '').catch(() => '');
  if (status === 'DONE') {
    const leftCreatePage = async () => page.waitForURL((url) => url.toString() !== createPageUrl, { timeout: 120000 })
      .then(() => true)
      .catch(() => false);
    if (!await leftCreatePage()) {
      await page.evaluate(() => {
        if (window.apex && typeof window.apex.submit === 'function') {
          window.apex.submit('CREATE_APP');
        }
      }).catch(() => {});
      if (!await leftCreatePage()) {
        throw new Error('Application creation reached DONE but did not navigate away from the create application page');
      }
    }
    await page.waitForLoadState('domcontentloaded', { timeout: 60000 }).catch(() => {});
  }
  if (status === 'ERROR' || status === 'ORA_ERROR') {
    const message = await page.evaluate(() => document.querySelector('#P1_ERROR_MESSAGE')?.value || document.querySelector('#P56_ERROR_MESSAGE')?.value || '').catch(() => '');
    throw new Error(`Application creation failed${message ? `: ${message}` : ''}`);
  }
  if (!completed) {
    const progressText = await page.locator('.ui-dialog-content, .a-Processing, body').first().innerText({ timeout: 5000 }).catch(() => '');
    throw new Error(`Timed out waiting for application creation to complete${status ? `; status=${status}` : ''}${progressText ? `; progress=${progressText.trim()}` : ''}`);
  }
}

async function screenshot(page, evidenceDir, name) {
  const file = path.join(evidenceDir, `${name}.png`);
  await page.screenshot({ path: file, fullPage: true });
  return file;
}

async function gotoApex(page, url) {
  try {
    await page.goto(url, { waitUntil: 'domcontentloaded' });
  } catch (error) {
    if (!String(error.message || error).includes('net::ERR_ABORTED')) {
      throw error;
    }
  }
  await page.waitForLoadState('domcontentloaded', { timeout: 30000 }).catch(() => {});
}

async function findRunApplicationUrl(page, appId) {
  const anchors = await page.locator('a').evaluateAll((links, targetAppId) => links.map((link) => ({
    href: link.href || '',
    text: link.textContent || '',
    title: link.getAttribute('title') || '',
    label: link.getAttribute('aria-label') || '',
    className: link.getAttribute('class') || '',
  })).filter((link) => {
    const searchableText = `${link.text} ${link.title} ${link.label} ${link.className}`;
    return new RegExp(`f\\?p=${targetAppId}:1`, 'i').test(link.href)
      || /Run Application/i.test(searchableText);
  }), appId);

  const exactTraditional = anchors.find((link) => new RegExp(`f\\?p=${appId}:1`, 'i').test(link.href));
  if (exactTraditional) {
    return exactTraditional.href;
  }
  const runApplication = anchors.find((link) => /Run Application/i.test(`${link.text} ${link.title} ${link.label}`));
  return runApplication ? runApplication.href : '';
}

function isBuilderApplicationPage(page, bodyText, appId) {
  const url = page.url();
  return /\/app-builder\//i.test(url)
    || (new RegExp(`Application\\s+${appId}\\b`, 'i').test(bodyText)
      && /Run Application|Edit Application Definition|Create Page/i.test(bodyText));
}

function isInvalidGeneratedAppPage(bodyText) {
  return /ERR-7620|404\s+Not Found|Could not determine workspace|Database Connection Error|HTTP Status Code:\s*571/i.test(bodyText);
}

async function loginWorkspace(page, opts) {
  const workspaceSelectors = [
    '#F4550_P1_COMPANY',
    '#P101_COMPANY',
    'input[name$="_COMPANY"]',
    'input[placeholder*="Workspace" i]',
  ];
  const loginUrls = [
    `${opts.ordsUrl}/`,
    `${opts.ordsUrl}/f?p=4550:1`,
  ];

  let workspaceInput = null;
  for (const loginUrl of loginUrls) {
    await page.goto(loginUrl, { waitUntil: 'domcontentloaded' });
    try {
      workspaceInput = await visibleLocator(page, workspaceSelectors);
      break;
    } catch {
      // Try the next known APEX builder login URL shape.
    }
  }
  if (!workspaceInput) {
    throw new Error(`None of these selectors became visible: ${workspaceSelectors.join(', ')}`);
  }

  await workspaceInput.fill(opts.workspace);
  await fillFirst(page, [
    '#F4550_P1_USERNAME',
    '#P101_USERNAME',
    'input[name$="_USERNAME"]',
    'input[autocomplete="username"]',
  ], opts.username);
  await fillFirst(page, [
    '#F4550_P1_PASSWORD',
    '#P101_PASSWORD',
    'input[name$="_PASSWORD"]',
    'input[type="password"]',
  ], opts.password);
  await waitForApexSubmit(page);
  await clickFirst(page, [
    '#B232005500580944564',
    'button:has-text("Sign In")',
    'button:has-text("Sign in")',
    'button[type="submit"]',
  ]);
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => {});

  const bodyText = await page.locator('body').innerText({ timeout: 30000 });
  if (/Sign in to your workspace|Workspace\s+Username\s+Password/i.test(bodyText)) {
    throw new Error('Workspace login did not leave the sign-in page');
  }

  if (!apexSessionFromUrl(page.url())) {
    await page.goto(`${opts.ordsUrl}/`, { waitUntil: 'domcontentloaded' });
    await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => {});
  }
}

async function createApplication(page, opts) {
  let legacySession = apexSessionFromUrl(page.url()) || await apexSessionFromPage(page);

  if (legacySession) {
    await page.goto(`${opts.ordsUrl}/f?p=4000:1500:${legacySession}::NO::P1500_SHOW:`, { waitUntil: 'domcontentloaded' });
  } else {
    const appBuilderLink = page.locator('a.app-builder, a:has-text("App Builder")').first();
    if (await appBuilderLink.count()) {
      const href = await appBuilderLink.getAttribute('href');
      await page.goto(new URL(href, page.url()).toString(), { waitUntil: 'domcontentloaded' });
    } else {
      await page.goto(`${opts.ordsUrl}/f?p=4000:1500`, { waitUntil: 'domcontentloaded' });
    }
  }

  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => {});
  legacySession = apexSessionFromUrl(page.url()) || await apexSessionFromPage(page);
  if (legacySession) {
    await page.goto(`${opts.ordsUrl}/f?p=4000:56:${legacySession}::NO:56::`, { waitUntil: 'domcontentloaded' });
  } else {
    await page.goto(`${opts.ordsUrl}/f?p=4000:56`, { waitUntil: 'domcontentloaded' });
  }
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => {});

  if (!(await page.locator('#P56_APP_NAME, input[name="P56_APP_NAME"]').count())) {
    const newApplicationLink = page.locator('a:has-text("New Application")').first();
    if (await newApplicationLink.count()) {
      await Promise.all([
        page.waitForLoadState('domcontentloaded').catch(() => {}),
        newApplicationLink.click(),
      ]);
      await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => {});
    }
  }

  try {
    await fillFirst(page, [
      '#P1_APP_NAME',
      'input[name="P1_APP_NAME"]',
      '#P56_APP_NAME',
      'input[name="P56_APP_NAME"]',
      'input[id$="_APP_NAME"]',
      'input[name$="_APP_NAME"]',
      'input[placeholder*="Name" i]',
      'input[type="text"]',
    ], opts.appName);
  } catch (error) {
    throw new Error(`${error.message}; current URL: ${page.url()}`);
  }

  if (opts.appId) {
    const candidates = ['#P1_APP_ID', '#P56_APP_ID', '#P56_APPLICATION_ID', 'input[name="P1_APP_ID"]', 'input[name="P56_APP_ID"]'];
    for (const selector of candidates) {
      const locator = page.locator(selector).first();
      if (await locator.count()) {
        await locator.fill(opts.appId);
        break;
      }
    }
  }

  let plannedAppId = opts.appId;
  if (!plannedAppId) {
    for (const selector of ['#P1_APP_ID', '#P56_APP_ID', '#P56_APPLICATION_ID', 'input[name="P1_APP_ID"]', 'input[name="P56_APP_ID"]']) {
      const locator = page.locator(selector).first();
      if (await locator.count()) {
        plannedAppId = await locator.inputValue().catch(() => '');
        if (plannedAppId) {
          break;
        }
      }
    }
  }

  await screenshot(page, opts.evidenceDir, 'create-application-before');
  await waitForApexSubmit(page);
  await submitCreateApplication(page);
  await waitForApplicationCreationComplete(page);
  await page.waitForLoadState('networkidle', { timeout: 60000 }).catch(() => {});
  await screenshot(page, opts.evidenceDir, 'create-application-after');

  const bodyText = await page.locator('body').innerText({ timeout: 30000 });
  const creationStatus = await page.evaluate(() => document.querySelector('#P1_STATUS')?.value || document.querySelector('#P56_STATUS')?.value || '').catch(() => '');
  if (/Create an Application/i.test(bodyText)
      && creationStatus !== 'DONE'
      && await page.locator('#P1_APP_NAME, #P56_APP_NAME, input[name="P1_APP_NAME"], input[name="P56_APP_NAME"]').count()) {
    throw new Error('Application creation did not leave the create application page');
  }
  const appIdMatch = bodyText.match(/Application\s+(\d+)/i) || page.url().match(/[?&]f?p=(\d+)/i);
  const detectedAppId = appIdMatch ? appIdMatch[1] : '';
  const builderAppIds = new Set(['4000', '4500', '4550']);
  const appId = opts.appId || plannedAppId || (builderAppIds.has(detectedAppId) ? '' : detectedAppId);
  return {
    appId,
    appAlias: slugify(opts.appName),
    session: apexSessionFromUrl(page.url()) || await apexSessionFromPage(page),
    runUrl: appId ? await findRunApplicationUrl(page, appId) : '',
  };
}

async function loginGeneratedApplication(page, opts, app) {
  if (!app.appId) {
    throw new Error('Generated application ID was not detected');
  }
  const appUrls = [
    app.runUrl && /f\?p=/i.test(app.runUrl) ? app.runUrl : '',
    app.session ? `${opts.ordsUrl}/${opts.workspace}/f?p=${app.appId}:1:${app.session}` : '',
    app.session ? `${opts.ordsUrl}/f?p=${app.appId}:1:${app.session}` : '',
    `${opts.ordsUrl}/${opts.workspace}/f?p=${app.appId}:1`,
    `${opts.ordsUrl}/f?p=${app.appId}:1`,
  ].filter(Boolean);
  let bodyText = '';
  for (const appUrl of appUrls) {
    await gotoApex(page, appUrl);
    bodyText = await page.locator('body').innerText({ timeout: 30000 });
    if (!isInvalidGeneratedAppPage(bodyText)
        && !isBuilderApplicationPage(page, bodyText, app.appId)) {
      break;
    }
  }
  if (/404\s+Not Found|Application with the alias .* does not exist/i.test(bodyText)) {
    throw new Error(`Generated application did not open with traditional f?p URL: ${app.appId}`);
  }

  const passwordInput = page.locator('#P9999_PASSWORD, input[type="password"]').first();
  if (await passwordInput.count()) {
    const workspaceInput = page.locator('#F4550_P1_COMPANY, #P101_COMPANY, input[name$="_COMPANY"], input[placeholder*="Workspace" i]').first();
    if (await workspaceInput.count()) {
      await workspaceInput.fill(opts.workspace);
    }
    await fillFirst(page, [
      '#P9999_USERNAME',
      '#F4550_P1_USERNAME',
      '#P101_USERNAME',
      'input[name$="_USERNAME"]',
      'input[autocomplete="username"]',
    ], opts.username);
    await fillFirst(page, [
      '#P9999_PASSWORD',
      '#F4550_P1_PASSWORD',
      '#P101_PASSWORD',
      'input[name$="_PASSWORD"]',
      'input[type="password"]',
    ], opts.password);
    await waitForApexSubmit(page);
    await clickFirst(page, [
      'button:has-text("Sign In")',
      'button:has-text("Sign in")',
      'button[type="submit"]',
    ]);
    await page.waitForURL((url) => !/4550|workspace-sign-in/i.test(url.toString()), { timeout: 60000 }).catch(() => {});
    await page.waitForLoadState('networkidle', { timeout: 60000 }).catch(() => {});
  }

  bodyText = await page.locator('body').innerText({ timeout: 30000 });
  if (/Sign in|Workspace\s+Username\s+Password/i.test(bodyText)) {
    throw new Error('Generated application login did not leave the sign-in page');
  }
  if (/ORA-\d+|ERR-\d+|Internal Server Error/i.test(bodyText)) {
    throw new Error('Generated application rendered an Oracle/APEX error page');
  }
  if (/Database Connection Error|HTTP Status Code:\s*571/i.test(bodyText)) {
    throw new Error('Generated application rendered an ORDS database connection error page');
  }
  if (isBuilderApplicationPage(page, bodyText, app.appId)) {
    throw new Error('Traditional f?p URL opened App Builder instead of the generated runtime application');
  }
  if (!bodyText.includes(opts.appName) && !/\bHome\b/i.test(bodyText)) {
    throw new Error('Generated application did not render the expected Home page');
  }

  return screenshot(page, opts.evidenceDir, 'application-home');
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const timestamp = new Date().toISOString().replace(/[-:T.Z]/g, '').slice(0, 14);
  const opts = {
    ordsUrl: requireArg(args, 'ords-url').replace(/\/$/, ''),
    workspace: args.workspace || 'demo',
    username: args.username || 'demo',
    password: args.password || 'demo',
    evidenceDir: requireArg(args, 'evidence-dir'),
    timeout: Number(args.timeout || 120000),
    appName: args['app-name'] || `Rapid Apex Smoke ${timestamp}`,
    appId: args['app-id'] || '',
  };

  await fs.mkdir(opts.evidenceDir, { recursive: true });

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  page.setDefaultTimeout(opts.timeout);

  try {
    try {
      await loginWorkspace(page, opts);
      const workspaceScreenshot = await screenshot(page, opts.evidenceDir, 'workspace-home');
      const app = await createApplication(page, opts);
      const appScreenshot = await loginGeneratedApplication(page, opts, app);
      const result = {
        status: 'passed',
        ordsUrl: opts.ordsUrl,
        workspace: opts.workspace,
        appName: opts.appName,
        appId: app.appId,
        appAlias: app.appAlias,
        finalUrl: page.url(),
        evidence: {
          workspaceHome: workspaceScreenshot,
          applicationHome: appScreenshot,
        },
      };
      console.log(JSON.stringify(result, null, 2));
    } catch (error) {
      await screenshot(page, opts.evidenceDir, 'failure').catch(() => {});
      try {
        const html = await page.content();
        await fs.writeFile(path.join(opts.evidenceDir, 'failure.html'), html);
        await fs.writeFile(path.join(opts.evidenceDir, 'failure-url.txt'), `${page.url()}\n`);
      } catch {
        // The page may still be navigating while preserving the original error.
      }
      throw error;
    }
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(`Browser smoke failed: ${error.message}`);
  process.exit(1);
});
