# Lighthouse CI Integration

This project uses Lighthouse CI to analyze Core Web Vitals and performance metrics **ONLY when manually triggered** via button clicks or comments in pull requests.

**💰 Cost-Optimized Design:**

- **No automatic runs** on PR creation or commits
- **On-demand testing only** when specifically requested
- **Saves CI/CD costs** by running only when needed

## 🎯 **Button-Triggered Testing** (Primary Method)

### **How to Run Lighthouse CI:**

1. **🖱️ Click Button** → Use the "Run Lighthouse CI" button in PR description
2. **💬 Comment** → Write `/lighthouse run` in PR comments
3. **🎛️ Manual** → Go to Actions tab → Lighthouse CI → Run workflow

### **PR Template Integration**

Each PR automatically includes a **"Run Lighthouse CI"** button in the description:

```markdown
## 🚀 Performance Testing

**Lighthouse CI Status:** ⚪ Not Run

### Run Performance Tests

**🔗 [▶️ Run Lighthouse CI Performance Tests](workflow-url)**
```

### **Live Status Updates:**

The PR description automatically updates to show current status:

- **⚪ Not Run** → Initial state
- **🟡 Running...** → Tests in progress with live progress link
- **🟢 Passed** → All tests successful (90%+ performance)
- **🟡 Passed with Warnings** → Tests passed but performance 70-89%
- **🔴 Failed** → Tests failed or performance < 70%

## 🔄 Baseline Management

### Setting Up Performance Baselines

Baselines allow you to compare current performance against a reference point (usually the target branch) and only fail if performance significantly degrades.

### 1. **Create Initial Baseline**

```bash
# 1. Checkout target branch (env1, env2, env3, or staging)
git checkout env1  # or env2, env3, staging

# 2. Start development server
yarn dev

# 3. Create baseline from current branch
./lighthouse-baseline.sh create-baseline
```

### 2. **Compare Against Baseline**

```bash
# 1. Switch to your feature branch
git checkout feature/my-feature

# 2. Ensure dev server is running
yarn dev

# 3. Compare current performance vs baseline
./lighthouse-baseline.sh compare
```

### 3. **Baseline Management Commands**

```bash
# View current baseline information
./lighthouse-baseline.sh view-baseline

# Reset/delete current baseline
./lighthouse-baseline.sh reset-baseline

# Show help
./lighthouse-baseline.sh help
```

### 4. **How Baseline Comparison Works**

1. **Baseline Creation**: Captures Core Web Vitals from master branch
2. **Comparison Logic**: Allows reasonable degradation thresholds:
   - LCP/FCP: +20% slower than baseline
   - CLS: +20% worse than baseline
   - TBT: +20% slower than baseline
3. **Smart Assertions**: Uses `"auto"` values that adapt to your baseline
4. **CI Integration**: Automatically uses baseline comparison in GitHub Actions
5. **Focus**: Only tests Core Web Vitals, ignoring accessibility/SEO for speed

### 5. **Example Workflow**

````bash
# Initial setup (once per target branch)
git checkout staging  # or env1, env2, env3
yarn dev
./lighthouse-baseline.sh create-baseline

# For each feature branch
git checkout -b feature/new-feature
# ... make changes ...
yarn dev
./lighthouse-baseline.sh compare  # Check if you introduced regressions

# If baseline needs updating (after target branch changes)
git checkout staging  # or your target branch
git pull origin staging  # or your target branch
./lighthouse-baseline.sh reset-baseline
./lighthouse-baseline.sh create-baseline
``` Lighthouse CI to automatically analyze Core Web Vitals and performance metrics for every pull request.

## 🚀 Features

- **Core Web Vitals Focus**: Only tests the 4 essential performance metrics that matter most
- **Baseline Comparison**: Only fail if Core Web Vitals get worse than previous baseline
- **Smart Regression Detection**: Adapts to your actual performance, not arbitrary thresholds
- **Merge Protection**: PRs cannot be merged until Core Web Vitals pass (unless skipped)
- **Skip Option**: Add `[skip lighthouse]` to PR title/description to bypass checks
- **Manual Recheck**: Multiple ways to rerun Lighthouse CI when needed
- **Comment Triggers**: Use `/lighthouse recheck` comments to trigger new runs
- **Fast Testing**: Only runs performance category for faster CI execution

## 📊 Core Web Vitals & Baseline Comparison

This Lighthouse CI configuration focuses exclusively on **Core Web Vitals** - the 4 metrics that Google uses to measure real user experience.

### 🎯 **Tested Metrics (Only These 4)**

#### 1. **Largest Contentful Paint (LCP)**
- **What it measures**: How long it takes for the largest visible element to load
- **Absolute threshold**: ≤ 4.0s (for local development)
- **Baseline threshold**: ≤ 20% slower than master branch

#### 2. **First Contentful Paint (FCP)**
- **What it measures**: How long it takes for any content to appear
- **Absolute threshold**: ≤ 3.0s (for local development)
- **Baseline threshold**: ≤ 20% slower than master branch

#### 3. **Cumulative Layout Shift (CLS)**
- **What it measures**: How much the page layout shifts unexpectedly
- **Absolute threshold**: ≤ 0.25 (for local development)
- **Baseline threshold**: ≤ 50% worse than master branch

#### 4. **Total Blocking Time (TBT)**
- **What it measures**: How long the main thread is blocked by JavaScript
- **Absolute threshold**: ≤ 600ms (for local development)
- **Baseline threshold**: ≤ 30% slower than master branch

### 🧠 **Smart Testing Modes**

#### **Local Development Mode**
- Uses absolute thresholds (shown above)
- Quick validation while developing
- Run with: `yarn lighthouse:local`

#### **CI/Baseline Mode**
- Compares against master branch baseline
- Only fails if **significantly worse** than baseline
- Automatically used in GitHub Actions

## � Rechecking Lighthouse Scores

## 🔄 Alternative Trigger Methods

### 1. **Comment Commands**
You can also trigger Lighthouse CI by commenting on the PR:

- `/lighthouse run` - Start new Lighthouse CI run
- `/lighthouse recheck` - Re-run Lighthouse CI
- `/recheck lighthouse` - Alternative recheck command

**Requirements:**
- Only collaborators with write access can trigger
- Must comment on an open pull request
- Bot reacts with 👍 to confirm command received

### 2. **Manual Workflow Dispatch**
Go to Actions tab → Lighthouse CI workflow → "Run workflow" button

**Options:**
- **PR Number**: Specify which PR to test
- **Custom URLs**: Override default test URLs

### 3. **Generate Button URLs**
Use the helper script to create proper button URLs:

```bash
./lighthouse-button-url.sh
# Outputs the correct workflow dispatch URL for PR templates
````

## 🛠️ Local Development

### Run Lighthouse CI Locally

```bash
# Start your development server
yarn dev

# In another terminal, run Lighthouse CI
yarn lighthouse:local
```

### Full CI Simulation

```bash
# Build and run full Lighthouse CI suite
yarn lighthouse:ci
```

### Available Scripts

- `yarn lhci:collect` - Collect Lighthouse data
- `yarn lhci:assert` - Run assertions against collected data
- `yarn lhci:upload` - Upload results to LHCI server
- `yarn lhci:autorun` - Run complete Lighthouse CI flow
- `yarn lighthouse:ci` - Build and run full CI suite
- `yarn lighthouse:local` - Quick local audit
- `yarn lighthouse:skip` - Skip command (for CI)

### Understanding Recheck Results

When Lighthouse CI runs (automatically or manually), you'll see results posted as PR comments with:

- **Run Number**: Each recheck gets a unique run number for tracking
- **Commit Hash**: Shows which commit was tested
- **Trigger Type**: Indicates if it was automatic, manual, or comment-triggered
- **Downloadable Artifacts**: Detailed reports available in GitHub Actions

**Result Indicators:**

- 🚢 **Automatic Check**: Triggered by new commits or PR events
- 🔄 **Manual Recheck**: Triggered via workflow dispatch
- 🔄 **Comment Triggered Recheck**: Triggered via PR comments

## 🚫 Skipping Lighthouse CI

To skip Lighthouse CI for a specific PR, add `[skip lighthouse]` anywhere in:

- PR title
- PR description
- Commit message

**Example:**

```
feat: add new feature [skip lighthouse]
```

## 🔧 Configuration

The Lighthouse CI configuration is in `lighthouserc.js`. Key areas:

### URLs to Test

Currently configured to test:

- Home page (`/`)
- About page (`/about`)
- Contact page (`/contact`)
- Properties page (`/properties`)

### Adjusting Thresholds

To modify performance thresholds, edit the `assert.assertions` section in `lighthouserc.js`.

### Chrome Flags

CI uses headless Chrome with flags optimized for CI environments.

## 📈 Monitoring Performance

### GitHub Actions

- View Lighthouse CI results in the Actions tab
- Download detailed reports from workflow artifacts
- Check PR comments for quick summaries

### Understanding Results

- **Green (✅)**: All thresholds met
- **Yellow (⚠️)**: Warnings but not blocking
- **Red (❌)**: Failed thresholds, blocking merge

## 🐛 Troubleshooting

### Common Issues

1. **Timeout Errors**

   - Increase `startServerReadyTimeout` in `lighthouserc.js`
   - Check that your build completes successfully

2. **Resource Budget Failures**

   - Optimize bundle sizes with `yarn analyze`
   - Consider code splitting for large JavaScript bundles

3. **Core Web Vitals Issues**

   - Use React DevTools Profiler to identify slow components
   - Optimize images and implement lazy loading
   - Minimize render-blocking resources

4. **CI Failures**

   - Check GitHub Actions logs for specific error messages
   - Ensure all dependencies are properly installed
   - Verify environment variables are set correctly

5. **Recheck Not Working**

   - Ensure you have write access to the repository
   - Check that the comment trigger workflow is enabled
   - Verify the comment contains the exact trigger phrases
   - Look for the 👍 reaction to confirm the trigger was received

6. **Manual Workflow Dispatch Not Available**

   - Ensure you have Actions write permissions
   - Check that the workflow file is on the default branch
   - Verify the workflow syntax is correct

7. **Baseline Comparison Issues**

   - Run `./lighthouse-baseline.sh view-baseline` to check if baseline exists
   - Ensure baseline was created from a stable master branch
   - Consider recreating baseline if master performance changed significantly
   - Check that baseline file `.lighthouseci/baseline-lhr.json` exists

8. **Performance Regressions False Positives**
   - Network conditions can cause variability - run tests multiple times
   - Consider updating baseline if master branch performance legitimately changed
   - Check if test environment (CPU, memory) is consistent
   - Use `aggregationMethod: "median-run"` to reduce variability

### Local Debugging

```bash
# Debug with verbose output
DEBUG=lhci:* yarn lighthouse:local

# Test specific URL
yarn dlx @lhci/cli collect --url=http://localhost:3000/specific-page
```

## 🔐 Environment Variables

For production LHCI server integration, set:

```bash
LHCI_GITHUB_APP_TOKEN=your_github_app_token
GITHUB_TOKEN=your_github_token
LHCI_TOKEN=your_lhci_server_token
```

## 📚 Resources

- [Lighthouse CI Documentation](https://github.com/GoogleChrome/lighthouse-ci)
- [Core Web Vitals Guide](https://web.dev/vitals/)
- [Lighthouse Scoring Guide](https://web.dev/performance-scoring/)
- [Next.js Performance Optimization](https://nextjs.org/docs/advanced-features/measuring-performance)

<!-- testing -->
