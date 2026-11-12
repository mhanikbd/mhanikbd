# ---------------------------------------------------------------------------
#  Content for the profile's generated graphics (everything under assets/).
#
#  Edit the text here, then either
#    - run  tools/build-assets.ps1  on your computer, or
#    - commit this file on GitHub: the "Profile assets" workflow rebuilds them.
#
#  Rules: plain text only, keep this file UTF-8, and only state things you
#  can stand behind. The README text itself lives in README.md.
# ---------------------------------------------------------------------------
@{
    Name      = 'Mehedi Hasan Anik'
    Monogram  = 'MHA'          # shown in the portrait until assets/source/profile-photo.jpg exists
    Headline  = 'Enterprise Product & Project Leader'
    Focus     = @('FinTech', 'AI', 'Digital Products')
    Location  = 'Dhaka, Bangladesh'
    Company   = 'naztech Inc'
    Since     = 2018
    GitHub    = 'mhanikbd'

    # The small code card in the About section. Keep each value short.
    CodeCard  = @{
        Role     = 'Product & Project Leader'
        Domains  = @('FinTech', 'Banking', 'AI')
        Approach = 'idea → technology → impact'
    }

    # Hero typing line: 2 to 4 phrases, at most 44 characters each.
    Rotating  = @(
        'Turning business needs into clear solutions'
        'Leading enterprise product delivery'
        'Designing FinTech and banking platforms'
        'Building faster with AI-driven workflows'
    )

    # Section headers: Title should stay under ~44 characters.
    Sections  = @{
        about        = @{ Num = '01'; Label = 'ABOUT';        Title = 'Where business, people and technology meet' }
        journey      = @{ Num = '02'; Label = 'JOURNEY';      Title = 'From freelancer to enterprise delivery' }
        work         = @{ Num = '03'; Label = 'WORK';         Title = 'Selected work across six practice areas' }
        capabilities = @{ Num = '04'; Label = 'CAPABILITIES'; Title = 'What I bring to the table' }
        activity     = @{ Num = '05'; Label = 'ACTIVITY';     Title = 'Building in public' }
        vision       = @{ Num = '06'; Label = 'VISION';       Title = 'What drives me' }
        connect      = @{ Num = '07'; Label = 'CONNECT';      Title = "Let's work together" }
    }

    # Career timeline, oldest first. Mark exactly one stage Current = $true.
    # Tags: 1 to 3 short uppercase words.
    Journey   = @(
        @{ Years = '2018 — 2020'; Title = 'Freelancing & Independent Development'
           Text  = 'Independent web and digital development, from first brief to launch'
           Tags  = @('FREELANCE', 'WEB'); Current = $false }
        @{ Years = '2021 — 2022'; Title = 'Web Development to Business Analysis'
           Text  = 'Professional web development, then a move into business analysis'
           Tags  = @('WEB', 'ANALYSIS'); Current = $false }
        @{ Years = '2022 — 2024'; Title = 'Business Analysis & Solution Design'
           Text  = 'Solution design and ownership of the product roadmap'
           Tags  = @('SOLUTIONS', 'ROADMAP'); Current = $false }
        @{ Years = '2024 — 2025'; Title = 'Senior Business Analyst'
           Text  = 'Leading enterprise solutions as a senior business analyst'
           Tags  = @('ENTERPRISE', 'LEADERSHIP'); Current = $false }
        @{ Years = '2025 — NOW'; Title = 'Project Management & Enterprise Delivery'
           Text  = 'Enterprise product delivery and AI-driven workflows at naztech Inc'
           Tags  = @('DELIVERY', 'AI', 'NOW'); Current = $true }
    )

    # "Who I've worked with" scale, smallest to largest.
    Clients   = @(
        @{ Label = 'Entrepreneurs'; Sub = 'Individual founders' }
        @{ Label = 'SMBs';          Sub = 'Small & medium businesses' }
        @{ Label = 'Startups';      Sub = 'Early-stage teams' }
        @{ Label = 'Growing orgs';  Sub = 'Scaling organizations' }
        @{ Label = 'Enterprises';   Sub = 'Large organizations' }
        @{ Label = 'Banks & FIs';   Sub = 'Financial institutions' }
    )

    # Six practice areas. Icon: bank, chart, web, rocket, pen, spark, target, code.
    Practice  = @(
        @{ Key = 'A'; Icon = 'bank';   Title = 'Enterprise & Banking'
           Lines = @('Requirements, solution design', 'and delivery for banks'); Note = 'SEE: DIGITAL LENDING' }
        @{ Key = 'B'; Icon = 'chart';  Title = 'FinTech & RegTech'
           Lines = @('Lending, regulatory and', 'financial product platforms'); Note = 'SEE: DIGITAL LENDING' }
        @{ Key = 'C'; Icon = 'web';    Title = 'Web Apps & Platforms'
           Lines = @('Web applications, CMS and', 'digital platforms'); Note = 'SEE: TRANSCRIBE STUDIO' }
        @{ Key = 'D'; Icon = 'rocket'; Title = 'Startups & Ventures'
           Lines = @('Digital products for founders', 'and early-stage startups'); Note = 'DETAILS ON REQUEST' }
        @{ Key = 'E'; Icon = 'pen';    Title = 'Branding & Creative'
           Lines = @('Brand experiences, websites', 'and campaign creatives'); Note = 'SEE: REELSMAKER, BGO FASHION' }
        @{ Key = 'F'; Icon = 'spark';  Title = 'AI & Automation'
           Lines = @('AI-powered tools and', 'automated workflows'); Note = 'SEE: TRANSCRIBE STUDIO' }
    )

    # Project cards. Kind: featured (full width, one only) or half.
    # Role must be honest: PERSONAL PROJECT, TEAM PROJECT, LED, DESIGNED, CONTRIBUTED...
    Projects  = @(
        @{ Slug = 'digital-lending-platform'; Kind = 'featured'
           Title = 'Digital Lending Platform'
           Tags  = @('ENTERPRISE & BANKING', 'FINTECH & REGTECH'); Role = 'TEAM PROJECT · NAZTECH'
           Lines = @('Bank-grade digital lending and account-opening platform for a',
                     'commercial bank in Bangladesh, from onboarding to collections.')
           Facts = @(
               @{ Big = 'Full lifecycle';  Small = 'Onboarding to collections' }
               @{ Big = 'Policy as data';  Small = 'Rules, approvals, waterfalls' }
               @{ Big = 'Regulator-aware'; Small = 'Loan classification built in' }
           )
           Stack = @('Java 21', 'Spring Boot', 'Next.js', 'TypeScript', 'PostgreSQL', 'Docker')
           Flow  = @('ORIGINATE', 'ASSESS', 'APPROVE', 'DISBURSE', 'REPAY', 'COLLECT') }
        @{ Slug = 'transcribe-studio'; Kind = 'half'
           Title = 'Transcribe Studio'
           Tags  = @('AI & AUTOMATION'); Role = 'PERSONAL PROJECT'
           Lines = @('Local web app that turns long meeting recordings into',
                     'editable text in Bangla and English, then exports Word,',
                     'PDF, TXT or SRT. Audio never leaves the machine.')
           Facts = @(
               @{ Big = 'Whisper large-v3';  Small = 'GPU speech recognition' }
               @{ Big = 'Private by design'; Small = 'Runs offline by default' }
           )
           Stack = @('Python', 'FastAPI', 'faster-whisper', 'FFmpeg') }
        @{ Slug = 'reelsmaker'; Kind = 'half'
           Title = 'ReelsMaker'
           Tags  = @('BRANDING & CREATIVE'); Role = 'PERSONAL PROJECT'
           Lines = @('Single-file web app that builds 1080×1920 video reels',
                     'from a simple form and encodes HD MP4 right in the',
                     'browser: no backend, no upload, no build step.')
           Facts = @(
               @{ Big = '100% client-side'; Small = 'MP4 export via WebCodecs' }
               @{ Big = 'Campaign-ready';   Small = 'Brand, slides, style presets' }
           )
           Stack = @('React 18', 'Tailwind CSS', 'WebCodecs', 'mp4-muxer') }
        @{ Slug = 'bgo-fashion'; Kind = 'half'
           Title = 'BGO Fashion: Coming Soon'
           Tags  = @('BRANDING & CREATIVE'); Role = 'WEBSITE BUILD'
           Lines = @('Pre-launch website for a fashion brand, with launch',
                     'offers, a product showcase and a cash-on-delivery',
                     'pre-order flow with order confirmation.')
           Facts = @(
               @{ Big = 'Launch offers';  Small = 'Limited-time deals' }
               @{ Big = 'Pre-order flow'; Small = 'Cash on delivery' }
           )
           Stack = @('HTML', 'CSS', 'JavaScript', 'Bootstrap 5') }
    )

    # Capability panels. Only list what you genuinely use.
    Capabilities = @(
        @{ Icon = 'target'; Title = 'Product & Business'; Sub = 'From requirements to release'
           Items = @('Product management', 'Project management', 'Business analysis', 'Solution architecture',
                     'Requirements engineering', 'Agile delivery', 'Enterprise technology consulting') }
        @{ Icon = 'code'; Title = 'Technology'; Sub = 'Building for the web and beyond'
           Items = @('Web development', 'WordPress & CMS', 'Application development', 'APIs & integrations',
                     'AI-assisted development', 'Workflow automation') }
        @{ Icon = 'spark'; Title = 'AI'; Sub = 'AI-first ways of working'
           Items = @('OpenAI', 'Claude Code', 'Codex', 'AI-powered dev workflows', 'Intelligent automation') }
        @{ Icon = 'pen'; Title = 'Creative'; Sub = 'Design that serves the business'
           Items = @('UI/UX design', 'Figma', 'Branding', 'Digital experiences', 'Website design',
                     'Creative problem-solving') }
    )
    StackLabel = 'STACKS ACROSS MY RECENT PROJECTS'
    Stack      = @('Java', 'Spring Boot', 'Next.js', 'TypeScript', 'Python', 'FastAPI', 'PostgreSQL', 'Docker')

    Philosophy = @{
        Lines     = @('Technology is not just about writing code.',
                      'It is about understanding people, solving problems,',
                      'creating opportunities and building',
                      'something meaningful.')
        Interests = @('AI-first development', 'Digital products', 'Enterprise transformation',
                      'Entrepreneurship', 'Creative technology', 'Scalable business solutions')
    }

    Connect = @{
        Eyebrow = "LET'S CONNECT"
        Title   = "Let's build something meaningful."
        Lines   = @('Technology professionals, entrepreneurs, startup founders, product leaders',
                    'and businesses: if you have an idea worth building, I would love to hear it.')
    }

    # Buttons. Only buttons whose links are set in README.md are shown there.
    Buttons = @(
        @{ Slug = 'github';   Label = 'View repositories' }
        @{ Slug = 'linkedin'; Label = 'Connect on LinkedIn' }
        @{ Slug = 'website';  Label = 'Visit my website' }
        @{ Slug = 'email';    Label = 'Email me' }
    )
}
