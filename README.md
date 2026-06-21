# 팀 업무 공유 보드 — 배포 가이드

> **이 가이드는 코딩 경험이 없는 분도 따라할 수 있도록 작성되었습니다.**  
> 순서대로 진행하면 약 15~20분 안에 완료할 수 있습니다.

---

## 목차

1. [Supabase 프로젝트 설정](#1-supabase-프로젝트-설정)
2. [데이터베이스 스키마 실행](#2-데이터베이스-스키마-실행)
3. [Supabase 연결 정보 확인 및 입력](#3-supabase-연결-정보-확인-및-입력)
4. [Cloudflare Pages 배포](#4-cloudflare-pages-배포)
5. [커스텀 도메인 연결](#5-커스텀-도메인-연결)
6. [보안 주의사항](#6-보안-주의사항)
7. [자주 묻는 문제와 해결법](#7-자주-묻는-문제와-해결법)

---

## 1. Supabase 프로젝트 설정

### 1-1. 계정 만들기

1. [supabase.com](https://supabase.com) 접속 → **Start your project** 클릭
2. GitHub 계정으로 로그인 (없으면 이메일로 가입)

### 1-2. 새 프로젝트 만들기

1. 로그인 후 대시보드에서 **New project** 클릭
2. 아래 정보 입력:
   - **Organization**: 기본값 유지
   - **Name**: 원하는 이름 (예: `team-work-board`)
   - **Database Password**: 강력한 비밀번호 입력 후 **반드시 기록해두기** (나중에 필요할 수 있음)
   - **Region**: `Northeast Asia (Seoul)` 선택 (빠른 응답 속도)
3. **Create new project** 클릭
4. ⏳ 프로젝트 초기화에 1~2분 소요됩니다. 완료될 때까지 기다려주세요.

---

## 2. 데이터베이스 스키마 실행

### 2-1. SQL Editor 열기

1. 왼쪽 사이드바에서 **SQL Editor** 아이콘 클릭 (코드 아이콘 `</>`)
2. **New query** 클릭

### 2-2. 스키마 SQL 실행

1. `supabase-schema.sql` 파일을 텍스트 편집기(메모장, TextEdit 등)로 열기
2. 파일 내용 전체 선택 (Ctrl+A / Cmd+A) 후 복사
3. Supabase SQL Editor 입력창에 붙여넣기
4. 오른쪽 상단 **RUN** 버튼 클릭
5. 아래에 오류 없이 완료 메시지가 나오면 성공

> **⚠️ Storage 버킷 오류가 나는 경우**  
> `permission denied for table buckets` 오류가 나면 아래 방법으로 버킷을 직접 만들어주세요:
> 1. 왼쪽 사이드바 → **Storage** 클릭
> 2. **New bucket** 클릭
> 3. Bucket name: `work-images`, **Public bucket** 체크 → Save
> 4. **Policies** 탭 → **New policy** → "Allow access to all users" 선택 → Save

### 2-3. Realtime 활성화 확인

1. 왼쪽 사이드바 → **Database** → **Replication** 클릭
2. `work_entries`와 `sns_metrics` 테이블이 활성화되어 있는지 확인
3. 비활성화 상태라면 토글을 눌러 활성화

---

## 3. Supabase 연결 정보 확인 및 입력

### 3-1. URL과 anon key 확인

1. 왼쪽 사이드바 → **Project Settings** (톱니바퀴 아이콘)
2. **API** 탭 클릭
3. 아래 두 값을 복사해둡니다:
   - **Project URL**: `https://xxxxxxxxxxxx.supabase.co` 형태
   - **anon / public** key: `eyJhbGciOiJIUzI1NiIs...` 형태의 긴 문자열

### 3-2. index.html에 값 입력

1. `index.html` 파일을 텍스트 편집기로 열기  
   (Windows: 메모장, Mac: TextEdit — 단, TextEdit는 서식 없음 모드로 열어야 함)
2. 파일 상단에서 아래 부분을 찾습니다:

```javascript
const SUPABASE_URL     = 'YOUR_SUPABASE_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
```

3. `YOUR_SUPABASE_URL` 자리에 복사한 Project URL 붙여넣기
4. `YOUR_SUPABASE_ANON_KEY` 자리에 anon key 붙여넣기
5. 저장 (Ctrl+S / Cmd+S)

완성 예시:
```javascript
const SUPABASE_URL     = 'https://abcdefghij.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

### 3-3. 로컬에서 테스트 (선택사항)

`index.html` 파일을 브라우저에서 직접 열어 테스트할 수 있습니다.  
단, Chrome의 경우 CORS 오류가 날 수 있으므로 Firefox나 Safari로 테스트하세요.

---

## 4. Cloudflare Pages 배포

### 방법 A: 폴더 직접 업로드 (간편, 권장)

1. [dash.cloudflare.com](https://dash.cloudflare.com) 접속 → 로그인 (없으면 가입)
2. 왼쪽 메뉴 → **Workers & Pages** 클릭
3. **Pages** 탭 → **Create a project** 클릭
4. **Direct Upload** 탭 선택
5. **Create project** 클릭 후 프로젝트 이름 입력 (예: `team-board`)
6. **Upload assets** 클릭 → `index.html` 파일 드래그 앤 드롭 (또는 클릭해서 선택)
7. **Deploy site** 클릭
8. 배포 완료 후 `https://team-board.pages.dev` 형태의 URL이 생성됩니다

> **폴더째로 업로드하려면**: `team-work-board` 폴더 전체를 드래그 앤 드롭하면 됩니다.

### 방법 B: GitHub 연동 (업데이트 시 자동 배포)

> Git/GitHub를 모르시면 방법 A를 사용하세요. 이 방법은 코드를 수정할 때마다 자동으로 배포됩니다.

1. [github.com](https://github.com) 가입 후 새 저장소(Repository) 만들기
   - `New repository` → 이름 입력 → **Public** 또는 **Private** 선택 → Create
2. `index.html`, `supabase-schema.sql`, `README.md` 파일을 저장소에 업로드
   - **Add file** → **Upload files** → 파일 드래그 → **Commit changes**
3. Cloudflare Pages에서 **Connect to Git** 탭 선택
4. GitHub 계정 연결 → 방금 만든 저장소 선택
5. 빌드 설정:
   - **Build command**: (비워두기)
   - **Build output directory**: `/`
6. **Save and Deploy** 클릭

---

## 5. 커스텀 도메인 연결

> 팀이 구매한 도메인을 Cloudflare Pages에 연결하는 방법입니다.

### 5-1. Cloudflare에 도메인 등록 (도메인이 Cloudflare에 없는 경우)

1. [dash.cloudflare.com](https://dash.cloudflare.com) → **Add a site** 클릭
2. 도메인 입력 → **Add site** → Free 플랜 선택
3. Cloudflare가 제공하는 네임서버(Nameserver) 주소 2개를 확인
4. 도메인을 구매한 사이트(가비아, 닷홈 등)의 관리 페이지에서 네임서버를 Cloudflare 값으로 변경
5. 최대 24시간 소요 (보통 몇 분 이내)

### 5-2. Pages에 커스텀 도메인 추가

1. Cloudflare Pages 프로젝트 → **Custom domains** 탭
2. **Set up a custom domain** 클릭
3. 사용할 도메인 입력 (예: `board.yourdomain.com` 또는 `yourdomain.com`)
4. **Continue** 클릭
5. DNS 레코드 설정 확인 화면이 나옵니다:
   - 루트 도메인(`yourdomain.com`): `CNAME` 레코드가 자동 추가됨
   - 서브도메인(`board.yourdomain.com`): 동일하게 자동 추가됨
6. **Activate domain** 클릭
7. HTTPS 인증서가 자동으로 발급됩니다 (수 분 소요)

---

## 6. 보안 주의사항

### ⚠️ anon key에 대해 알아야 할 것

이 앱은 로그인 없이 링크를 아는 팀원 누구나 접근할 수 있도록 설계되어 있습니다.  
Supabase의 `anon` 키는 코드에 포함되어 누구나 볼 수 있는 키이지만, **이것은 의도된 설계**입니다.

- ✅ `anon` 키로는 RLS 정책에서 허용한 작업만 가능합니다
- ✅ 데이터베이스 구조를 변경하거나 다른 프로젝트에 접근할 수 없습니다
- ⚠️ 링크를 아는 사람이라면 누구든 Supabase API로 직접 데이터를 조회/수정할 수 있습니다
- ⚠️ 민감한 정보(개인정보, 비밀 전략 등)는 이 앱에 저장하지 마세요

**향후 보안 강화 방법**: Supabase Auth의 매직링크(이메일로 1회용 로그인 링크 발송)를 도입하면 팀원만 접근하도록 제한할 수 있습니다.

---

## 7. 자주 묻는 문제와 해결법

### 🔴 "설정이 필요합니다" 화면이 뜬다
- `index.html` 파일에 `SUPABASE_URL`과 `SUPABASE_ANON_KEY`가 입력되지 않았습니다.
- [3-2 단계](#3-2-indexhtml에-값-입력)로 돌아가서 값을 입력해주세요.

### 🔴 데이터가 저장되지 않는다 / 401·403 오류
- Supabase SQL Editor에서 아래 명령을 실행하여 RLS 정책이 설정되어 있는지 확인하세요:
  ```sql
  SELECT tablename, policyname FROM pg_policies
  WHERE tablename IN ('work_entries', 'sns_metrics');
  ```
- 결과가 없으면 `supabase-schema.sql`의 **4~5번 섹션**을 다시 실행하세요.

### 🔴 이미지가 업로드되지 않는다
- Storage 버킷 `work-images`가 **Public**으로 설정되어 있는지 확인하세요.
- Supabase 대시보드 → Storage → `work-images` 버킷 → Settings → **Public bucket** 체크 여부 확인

### 🟡 사이트가 갑자기 느리거나 안 열린다
- **Supabase 무료 플랜은 7일간 요청이 없으면 프로젝트가 자동으로 일시정지됩니다.**
- Supabase 대시보드에 로그인하여 프로젝트가 일시정지 상태인지 확인하세요.
- 일시정지된 경우 **Resume project** 버튼을 눌러 재개하세요 (약 1~2분 소요).
- 앱에서 접속할 때 "서버가 깨어나는 중" 메시지가 나타날 수 있습니다 — 잠시 기다렸다가 새로고침하세요.

### 🟡 실시간 동기화가 안 된다
- Supabase 대시보드 → Database → **Replication** 탭에서 두 테이블의 Realtime이 활성화되어 있는지 확인하세요.
- 우측 상단의 초록색 점이 표시되면 연결된 것입니다.

### 🟡 로컬에서는 되는데 배포 후에 안 된다
- 브라우저 개발자 도구 (F12 → Console 탭)에서 오류 메시지를 확인하세요.
- CORS 오류가 나는 경우: Supabase 대시보드 → Authentication → **URL Configuration** → `Additional redirect URLs`에 배포 URL을 추가하세요.

### 🟡 보고서 JPG/PDF가 깨진다
- 브라우저 팝업 차단이 켜져 있으면 파일 다운로드가 막힐 수 있습니다.
- 브라우저 주소창 오른쪽의 팝업 차단 아이콘을 클릭하고 허용해주세요.

### 🔵 모바일에서 레이아웃이 깨진다
- 최신 버전의 Chrome 또는 Safari를 사용해주세요.
- 화면 방향을 가로로 바꾸면 더 쾌적하게 사용할 수 있습니다.

---

## 파일 구성

```
team-work-board/
├── index.html          ← 전체 앱 (이 파일 하나로 동작)
├── supabase-schema.sql ← 데이터베이스 초기화 SQL (1회만 실행)
└── README.md           ← 이 가이드 파일
```

---

## 업데이트 방법

코드를 수정한 후:

- **방법 A (직접 업로드)**: Cloudflare Pages → 프로젝트 → **Deployments** → **Upload assets** → 새 파일 업로드
- **방법 B (GitHub 연동)**: 저장소에 파일을 업로드/수정하면 자동으로 배포됩니다

---

*문의사항이 있으면 담당자에게 연락하세요.*
