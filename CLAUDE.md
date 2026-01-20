# 글로벌 CLAUDE.md

모든 프로젝트에 적용되는 글로벌 설정입니다. 신원, 보안 규칙, 프로젝트 구조 표준을 정의합니다.
대답은 한국어로 해.

## 계정 및 도구

- **GitHub**: YourUsername (SSH: `git@github.com:YourUsername/<repo>.git`)
- **Docker Hub**: `~/.docker/config.json`으로 인증
- **배포**: Dokploy (API URL은 `~/.env`에 저장)

> 이 섹션을 실제 계정과 도구로 커스터마이즈하세요.

---

## 절대 하지 말 것 (보안 게이트키퍼)

이 규칙들은 **절대적**입니다. 예외 없음.

### 민감한 데이터 게시 금지
- ❌ 비밀번호, API 키, 토큰을 git/npm/docker에 커밋 금지
- ❌ 소스 파일에 자격 증명 하드코딩 금지
- ❌ 에러 메시지나 로그에 비밀 정보 포함 금지

### .env 파일 커밋 금지
- ❌ `.env`를 git에 커밋 금지
- ✅ `.env`가 `.gitignore`에 있는지 항상 확인
- ✅ 플레이스홀더 값이 있는 `.env.example` 사용

### 검증 생략 금지
- 모든 커밋 전: 비밀 정보 미포함 확인
- 모든 푸시 전: 스테이징된 파일에 민감한 데이터 확인
- 모든 배포 전: 패키지 내용 감사

---

## 새 프로젝트 설정 (스캐폴딩 규칙)

새 프로젝트 생성 시 항상 다음을 수행:

### 1. 필수 파일 (즉시 생성)

| 파일 | 목적 | 비고 |
|------|------|------|
| `.env` | 환경 변수 | 커밋 금지 |
| `.env.example` | 플레이스홀더 템플릿 | 커밋 대상 |
| `.gitignore` | 무시 패턴 | .env 포함 필수 |
| `.dockerignore` | Docker 무시 패턴 | .gitignore와 유사하게 |
| `README.md` | 프로젝트 개요 | 환경변수 참조만, 하드코딩 금지 |
| `CLAUDE.md` | 프로젝트 지침 | 아래 필수 섹션 참고 |

### 2. 필수 디렉토리 구조

```
project-root/
├── src/               # 소스 코드
├── tests/             # 테스트 파일
├── docs/              # 문서
├── .claude/           # Claude 설정
│   ├── commands/      # 커스텀 슬래시 명령
│   ├── skills/        # 프로젝트별 스킬
│   └── settings.json  # 프로젝트 설정
└── scripts/           # 빌드/배포 스크립트
```

### 3. 필수 .gitignore 항목

```gitignore
# 환경 변수
.env
.env.*
.env.local
!.env.example

# 의존성
node_modules/
vendor/
__pycache__/
.venv/
bin/
obj/
packages/

# 빌드 출력
dist/
build/
.next/
*.pyc
*.dll
*.exe
*.pdb

# Claude 로컬 파일
.claude/settings.local.json
CLAUDE.local.md

# IDE
.idea/
.vscode/
*.swp
*.suo
*.user

# OS
.DS_Store
Thumbs.db
```

### 4. 필수 CLAUDE.md 섹션

모든 프로젝트 `CLAUDE.md`에 포함해야 할 내용:

```markdown
# 프로젝트명

## 개요
[프로젝트가 하는 일]

## 기술 스택
- 언어: [예: TypeScript, C#]
- 프레임워크: [예: Next.js, ASP.NET Core]
- 데이터베이스: [예: PostgreSQL, SQL Server]

## 명령어
- `dotnet run` — 개발 서버 시작
- `dotnet build` — 프로덕션 빌드
- `dotnet test` — 테스트 실행
- `dotnet format` — 코드 스타일 검사

## 아키텍처
[코드베이스 구조의 고수준 개요]

## 환경 변수
[필수 환경변수 목록 - 값 없이]
```

---

## 프레임워크별 규칙

### C# / .NET 프로젝트
- `Directory.Build.props`로 공통 설정 관리
- Nullable reference types 활성화 (`<Nullable>enable</Nullable>`)
- `ILogger<T>` 사용하여 로깅
- 비동기 메서드는 `Async` 접미사 사용
- `appsettings.json` + `appsettings.{Environment}.json` 패턴 사용
- 비밀 정보는 User Secrets 또는 환경변수로 관리
- 테스트: xUnit + FluentAssertions + NSubstitute 권장
- 코드 스타일: `.editorconfig` 설정 필수

### ASP.NET Core 프로젝트
- Minimal API 또는 Controller 기반 일관성 유지
- 의존성 주입(DI) 적극 활용
- `IOptions<T>` 패턴으로 설정 바인딩
- 미들웨어 순서 주의 (인증 → 권한 → 라우팅)
- Health Check 엔드포인트 포함 (`/health`)

### Python 프로젝트
- `pyproject.toml` 사용 (setup.py 대신)
- `src/` 레이아웃 사용
- `requirements.txt`와 `requirements-dev.txt` 모두 포함
- Ruff로 린팅 설정
- 타입 힌트 적극 사용 (mypy 또는 pyright)
- 가상환경: venv 또는 poetry 사용

### Node.js 프로젝트
- 진입점에 에러 핸들러 추가
- TypeScript strict 모드 사용
- ESLint + Prettier 설정
- Husky로 pre-commit 훅 설정

### Next.js 프로젝트
- App Router 사용 (Pages Router 아님)
- `src/app/` 디렉토리 구조 생성
- next.config.js에서 strict 모드 활성화

### Docker 프로젝트
- 멀티 스테이지 빌드 항상 사용
- root로 실행 금지
- Health check 포함
- `.dockerignore`에 `.git/` 포함 필수

---

## 품질 게이트

### 파일 크기 제한
- 파일당 300줄 초과 금지 (초과 시 분리)
- 함수당 50줄 초과 금지

### 커밋 전 필수 확인
- [ ] 모든 테스트 통과
- [ ] 빌드 에러 없음
- [ ] 린터 경고 없음
- [ ] 스테이징된 파일에 비밀 정보 없음

### CI/CD 요구사항
- GitHub Actions 워크플로우로 CI 구성
- Pre-commit 훅: Husky (Node.js) 또는 pre-commit (Python)

---

## 권장 MCP 서버

향상된 기능을 위해 다음 MCP 서버 추가 고려:

```bash
# 라이브 문서 접근
claude mcp add context7 -- npx -y @anthropic-ai/context7-mcp

# 브라우저 테스팅
claude mcp add playwright -- npx -y @anthropic-ai/playwright-mcp

# GitHub 통합
claude mcp add github -- npx -y @modelcontextprotocol/server-github
```

---

## 글로벌 명령어

`~/.claude/commands/`에 저장하여 모든 프로젝트에서 사용:

| 명령어 | 목적 |
|--------|------|
| `/new-project` | 스캐폴딩 규칙으로 프로젝트 생성 |
| `/security-check` | 비밀 정보 스캔, .gitignore 검증 |
| `/pre-commit` | 모든 품질 게이트 실행 |
| `/docs-lookup` | Context7로 문서 조회 |

---

*마지막 업데이트: 2025-01-20*
