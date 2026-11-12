# Maintaining the profile

This repository is the GitHub profile README for **mhanikbd**. GitHub shows `README.md` on the profile page because the repository has the same name as the account.

## How it fits together

| Part | What it is | Who changes it |
| --- | --- | --- |
| `README.md` | Page layout, About text, case notes and links | You, by hand |
| `profile.psd1` | Text for every graphic: name, headline, timeline, projects, capabilities, quote | You, by hand |
| `tools/build-assets.ps1` | Draws all graphics in `assets/` from `profile.psd1`, in dark and light versions | Runs automatically |
| `tools/update-stats.ps1` | Builds the GitHub activity card from live GitHub data | Runs daily |
| `.github/workflows/profile.yml` | Runs both scripts and the contribution animation, then commits the results | GitHub Actions |
| `assets/` | Generated graphics. Don't edit these files directly; they get overwritten. | Generated |

Every graphic comes in a `-dark.svg` and a `-light.svg` version. The README uses `<picture>` so GitHub shows the one that matches the visitor's theme.

## Everyday edits on github.com (no tools needed)

1. Open `profile.psd1` on GitHub and click the pencil icon.
2. Change the text, for example add a timeline stage or a project.
3. Commit the change.
4. The **Profile assets** workflow rebuilds every graphic in about a minute. Watch it under the **Actions** tab.

To change the README text, edit `README.md` the same way. It needs no rebuild.

## Common changes

**Add your LinkedIn, website or email buttons.**
In `README.md`, find the comment that starts `<!-- LINKEDIN:` (or `WEBSITE:` / `EMAIL:`). Put the real link where it says `YOUR-…`, then delete the `<!-- … -->` marker lines around it. The button graphics already exist.

**Add your profile photo.**
On Windows:

```powershell
powershell -ExecutionPolicy Bypass -File tools/prepare-photo.ps1 -Path "C:\path\to\photo.jpg"
powershell -ExecutionPolicy Bypass -File tools/build-assets.ps1
```

`prepare-photo.ps1` crops the photo to a small square at `assets/source/profile-photo.jpg`. The banner then shows the photo instead of the monogram. Use `-FocusY 0.3` if the face sits high in the frame. You can also upload a ready-made square JPEG to `assets/source/profile-photo.jpg` on GitHub, and the workflow will rebuild the banner.

**Add a project.**
Copy a `Kind = 'half'` block in `profile.psd1`, change its `Slug`, text and stack, then add a matching `<picture>` card and a `<details>` case-note block to `README.md`. Half cards sit in pairs inside one `<p align="center">`.

**Update the career timeline.**
Edit `Journey` in `profile.psd1`. Exactly one stage should have `Current = $true`; it gets the gold "now" marker.

## Building on your computer

Requires only Windows PowerShell (built into Windows):

```powershell
powershell -ExecutionPolicy Bypass -File tools/build-assets.ps1     # all design graphics
powershell -ExecutionPolicy Bypass -File tools/update-stats.ps1     # live stats card
powershell -ExecutionPolicy Bypass -File tools/update-stats.ps1 -FromCache   # redraw stats without calling GitHub
```

Then publish with Git from this folder:

```powershell
git add -A
git commit -m "Update profile"
git pull --rebase    # picks up the workflow's daily asset commits first
git push
```

## Content rules

- Only publish facts you can stand behind: no invented clients, numbers or results.
- Label each project with your honest role (personal project, team project, led, designed, contributed).
- Describe confidential clients without naming them, for example "a commercial bank in Bangladesh".
- Statistics come only from the GitHub API, never typed by hand.

## Design system

| Token | Dark | Light |
| --- | --- | --- |
| Background | `#060A14` | `#F5F8FC` |
| Panel | `#0B1222` | `#FFFFFF` |
| Text | `#F1F5F9` | `#0B1324` |
| Signature gradient | `#2DD4BF → #38BDF8 → #818CF8` | `#0D9488 → #0284C7 → #4F46E5` |
| Accent (sparingly) | `#F5B841` | `#B7791F` |

Type: **Sora** for headings, **JetBrains Mono** for labels, the system UI font for body text. Sora and JetBrains Mono are embedded in the graphics because GitHub images cannot load web fonts. Both fonts are under the SIL Open Font License; the license files are in `tools/fonts/`.

All animation is subtle and respects the visitor's "reduce motion" setting. Without animation, every graphic shows its finished state.
