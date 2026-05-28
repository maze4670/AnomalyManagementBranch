# GODOT_IMPLEMENTATION_PLAN.md

# Godot 구현 계획서

## 0. 문서 개요

### 0.1 문서 목적

이 문서는 `GAME_DESIGN_codex.md`를 기준으로 Godot 개발을 시작하기 전에 필요한 프로젝트 구조, 구현 범위, 개발 순서, Codex 작업 규칙을 정리한 구현 계획서다.

이 문서는 게임 기획을 새로 정하거나 바꾸는 문서가 아니다. 이미 확정된 기획을 Godot, GDScript, JSON 기반으로 안전하게 구현하기 위한 기준 문서다.

### 0.2 기준 문서

- `GAME_DESIGN_codex.md`

앞으로 구현, 코드 작성, 데이터 구조 설계, Codex 작업 지시는 이 문서를 기준으로 하되, 게임 기획 자체는 항상 `GAME_DESIGN_codex.md`를 최우선 기준으로 삼는다.

### 0.3 개발 전제

- 엔진: Godot
- 언어: GDScript
- 데이터 관리: JSON 파일
- 우선 배포 목표: Windows PC
- 장기 배포 목표: Steam 출시
- 현재 웹 프로토타입은 참고용으로만 보관한다.
- 최종 게임은 Godot에서 새 구조로 재구현한다.

### 0.4 핵심 개발 원칙

이 게임은 텍스트 기반 이상현상 추론 관리 게임이다.

플레이어는 이상현상관리지부장이 되어 보고서를 읽고, 대응을 선택하고, 60일 동안 해고당하지 않아야 한다.

이 게임은 다음 장르가 아니다.

- 자원 분배 게임이 아니다.
- 전투 게임이 아니다.
- 직원 육성 게임이 아니다.
- SCP 설정 복붙 게임이 아니다.

개발 과정에서 AI는 다음을 임의로 수행하면 안 된다.

- 게임 구조 변경
- 새 이상현상 추가
- 새 보고서 작성
- 밸런스 수치 확정 또는 변경
- 내부 수치, 확률, 선택지 효과량을 플레이어 UI에 표시

---

# 1. Godot 프로젝트 폴더 구조

## 1.1 확정 방향

이 프로젝트는 Steam 출시까지 고려해, 처음부터 확장 가능한 폴더 구조를 사용한다.

핵심 방향은 다음과 같다.

- 화면 UI와 게임 로직을 분리한다.
- JSON 데이터와 저장 구조를 별도로 관리한다.
- Codex가 작업할 때 수정 범위를 명확히 제한할 수 있게 한다.
- 나중에 프로젝트가 커져도 폴더 구조를 크게 갈아엎지 않도록 한다.

## 1.2 확정 폴더 구조

```text
res://
├── scenes/
│   ├── main_menu/
│   ├── briefing/
│   ├── work/
│   ├── archive/
│   ├── settings/
│   └── ending/
│
├── scripts/
│   ├── ui/
│   │   ├── main_menu/
│   │   ├── briefing/
│   │   ├── work/
│   │   ├── archive/
│   │   ├── settings/
│   │   └── ending/
│   │
│   ├── game/
│   │   ├── day_loop/
│   │   ├── anomalies/
│   │   ├── reports/
│   │   ├── choices/
│   │   ├── archive/
│   │   ├── trust/
│   │   └── endings/
│   │
│   ├── data/
│   ├── save/
│   └── autoload/
│
├── data/
│   ├── anomalies/
│   ├── reports/
│   ├── system/
│   └── text/
│
├── assets/
│   ├── fonts/
│   ├── images/
│   ├── sounds/
│   └── themes/
│
└── saves/
```

## 1.3 폴더별 역할

| 폴더 | 역할 |
|---|---|
| `scenes/` | Godot 화면 파일을 저장한다. |
| `scripts/ui/` | 화면 표시, 버튼 입력, 탭 전환 등 UI 코드를 저장한다. |
| `scripts/game/` | 하루 종료, 보고서 처리, 신뢰도, 엔딩 등 게임 규칙 코드를 저장한다. |
| `scripts/data/` | JSON 원본 데이터를 읽는 코드를 저장한다. |
| `scripts/save/` | 저장/불러오기 코드를 저장한다. |
| `scripts/autoload/` | 게임 전체에서 공유하는 상태 관리 코드를 저장한다. |
| `data/` | 게임 원본 JSON 데이터를 저장한다. |
| `assets/` | 글꼴, 이미지, 소리, 테마 파일을 저장한다. |
| `saves/` | 실제 저장 위치가 아니라 저장 구조 설명 또는 테스트용으로만 사용한다. |

실제 플레이어 저장 파일은 `saves/`가 아니라 Godot의 `user://` 경로에 저장한다.

---

# 2. 씬 구조

## 2.1 확정 방향

이 프로젝트는 큰 화면 씬과 탭 단위 하위 씬을 함께 사용한다.

큰 화면은 별도 씬으로 만들고, 근무 화면처럼 여러 기능이 들어가는 화면은 탭 단위로 하위 씬을 분리한다.

## 2.2 확정 씬 구조

```text
scenes/
├── main_menu/
│   └── MainMenu.tscn
│
├── briefing/
│   └── BriefingScreen.tscn
│
├── work/
│   ├── WorkScreen.tscn
│   ├── ReportTab.tscn
│   ├── CurrentAnomaliesTab.tscn
│   └── EndDayTab.tscn
│
├── archive/
│   └── ArchiveScreen.tscn
│
├── settings/
│   └── SettingsScreen.tscn
│
└── ending/
    └── EndingScreen.tscn
```

## 2.3 씬별 역할

| 씬 | 역할 |
|---|---|
| `MainMenu.tscn` | 근무 시작, 기록 보관실, 설정, 근무 종료 버튼을 제공한다. |
| `BriefingScreen.tscn` | 근무 시작 전 브리핑을 보여준다. 보고서 본문은 보여주지 않는다. |
| `WorkScreen.tscn` | 근무 화면 전체의 틀이다. 현재 일차, 잔여 대응 절차, 탭 전환을 담당한다. |
| `ReportTab.tscn` | 보고서 목록, 보고서 상세, 대응 선택, 대응 확정을 담당한다. |
| `CurrentAnomaliesTab.tscn` | 현재 회차에서 등장한 이상현상 문서를 보여준다. |
| `EndDayTab.tscn` | 하루 종료 확인과 하루 종료 요청을 담당한다. |
| `ArchiveScreen.tscn` | 기록 보관실 문서를 보여준다. |
| `SettingsScreen.tscn` | 볼륨, 화면, 텍스트 크기, 제작진 정보를 제공한다. |
| `EndingScreen.tscn` | GOOD/BAD 엔딩 결과를 보여준다. |

## 2.4 씬 구현 원칙

- `WorkScreen.tscn`은 근무 화면의 틀만 담당한다.
- 실제 기능은 `ReportTab.tscn`, `CurrentAnomaliesTab.tscn`, `EndDayTab.tscn`으로 나눈다.
- 하루 종료 계산, 신뢰도 계산, 후속 보고 예약, 특수 이벤트 판정은 씬에서 직접 처리하지 않는다.
- 이러한 내부 계산은 `scripts/game/`의 게임 로직 스크립트가 담당한다.
- 초기 개발에서는 작은 UI 부품 씬을 과도하게 만들지 않는다.

---

# 3. 스크립트 역할 분리

## 3.1 확정 방향

이 프로젝트는 UI 스크립트와 게임 로직 스크립트를 분리한다.

UI 스크립트는 플레이어가 보는 화면과 버튼을 담당하고, 게임 로직 스크립트는 하루 종료, 보고서 처리, 이상현상 상태, 기관 신뢰도, 엔딩 판정 같은 내부 규칙을 담당한다.

## 3.2 확정 스크립트 구조

```text
scripts/
├── ui/
│   ├── main_menu/
│   │   └── main_menu.gd
│   ├── briefing/
│   │   └── briefing_screen.gd
│   ├── work/
│   │   ├── work_screen.gd
│   │   ├── report_tab.gd
│   │   ├── current_anomalies_tab.gd
│   │   └── end_day_tab.gd
│   ├── archive/
│   │   └── archive_screen.gd
│   ├── settings/
│   │   └── settings_screen.gd
│   └── ending/
│       └── ending_screen.gd
│
├── game/
│   ├── day_loop/
│   │   └── day_manager.gd
│   ├── anomalies/
│   │   └── anomaly_manager.gd
│   ├── reports/
│   │   └── report_manager.gd
│   ├── choices/
│   │   └── choice_resolver.gd
│   ├── archive/
│   │   └── archive_manager.gd
│   ├── trust/
│   │   └── trust_manager.gd
│   └── endings/
│       └── ending_manager.gd
│
├── data/
│   └── data_manager.gd
│
├── save/
│   └── save_manager.gd
│
└── autoload/
    └── game_state.gd
```

## 3.3 스크립트별 역할

| 스크립트 | 역할 |
|---|---|
| `main_menu.gd` | 메인 메뉴 버튼과 화면 이동을 처리한다. |
| `briefing_screen.gd` | 브리핑 내용을 표시하고 근무 화면 이동을 처리한다. |
| `work_screen.gd` | 현재 일차, 잔여 대응 절차, 탭 전환을 표시한다. |
| `report_tab.gd` | 보고서 목록, 상세, 선택지, 확정 입력을 표시한다. |
| `current_anomalies_tab.gd` | 현재 관리 중인 이상현상 문서를 표시한다. |
| `end_day_tab.gd` | 하루 종료 확인과 요청만 처리한다. |
| `day_manager.gd` | 하루 시작, 하루 종료, 일차 증가, 전체 처리 순서를 총괄한다. |
| `report_manager.gd` | 활성 보고서, 처리 완료, 처리 지연, 후속 보고 예약을 관리한다. |
| `choice_resolver.gd` | 오늘 확정한 선택지를 기록하고 선택 결과 처리를 준비한다. |
| `anomaly_manager.gd` | 이상현상 상태, 안정화, 격리 실패, 새 이상현상 추가를 관리한다. |
| `trust_manager.gd` | 기관 신뢰도 내부 계산을 담당한다. |
| `ending_manager.gd` | GOOD/BAD 엔딩 판정을 담당한다. |
| `archive_manager.gd` | 기록 보관실 반영과 해금 정보를 관리한다. |
| `data_manager.gd` | JSON 원본 데이터를 읽는다. |
| `save_manager.gd` | 현재 회차, 기록 보관실, 설정 저장을 담당한다. |
| `game_state.gd` | 게임 전체에서 공유해야 하는 현재 상태를 보관한다. |

## 3.4 역할 분리 규칙

UI 스크립트가 할 수 있는 일:

- 텍스트 표시
- 버튼 클릭 처리
- 탭 전환
- 화면 이동 요청
- 보고서 목록과 상세 표시

UI 스크립트가 하면 안 되는 일:

- 상태 수치 계산
- 기관 신뢰도 계산
- 확률 판정
- 선택지 효과 적용
- 후속 보고 예약
- 새 이상현상 추가 판정
- 엔딩 조건 직접 계산

게임 규칙 계산은 반드시 `scripts/game/` 쪽에서 처리한다.

---

# 4. JSON 데이터 파일 구조

## 4.1 확정 방향

이 프로젝트는 폴더별 + 이상현상별 JSON 파일 분리 구조를 사용한다.

가장 중요한 원칙은 다음과 같다.

- 플레이어에게 보여지는 문서 데이터와 게임 내부 계산에 쓰이는 데이터를 분리한다.
- 원본 콘텐츠는 JSON에 넣고, 코드는 JSON을 읽어 게임을 진행한다.
- Codex는 사용자가 제공하지 않은 콘텐츠를 임의 생성하지 않는다.

## 4.2 확정 JSON 구조

```text
data/
├── anomalies/
│   ├── case_001_document.json
│   ├── case_014_document.json
│   └── ...
│
├── reports/
│   ├── case_001_reports.json
│   ├── case_014_reports.json
│   └── ...
│
├── system/
│   ├── day_rules.json
│   ├── new_anomaly_rules.json
│   ├── delay_penalty_rules.json
│   ├── special_event_rules.json
│   └── trust_rules.json
│
└── text/
    ├── briefing_messages.json
    ├── ui_messages.json
    ├── warning_messages.json
    └── ending_messages.json
```

## 4.3 JSON 폴더별 역할

| 폴더 | 역할 |
|---|---|
| `data/anomalies/` | 플레이어에게 보여지는 이상현상 문서를 저장한다. |
| `data/reports/` | 내부 보고 루트, 대응 선택지, 선택지 효과, 후속 보고 정보를 저장한다. |
| `data/system/` | 하루 행동 수, 확률표, 처리 지연 악영향, 신뢰도 기본값 같은 시스템 규칙을 저장한다. |
| `data/text/` | 브리핑 문구, UI 문구, 경고 문구, 엔딩 문구를 저장한다. |

## 4.4 `data/anomalies/` 규칙

포함 가능 정보:

- 식별명
- 별칭
- 분류
- 기본 설명
- 추가 설명

포함 금지 정보:

- 상태 수치
- 선택지 효과량
- 보고 루트 구조
- 내부 계산식
- 성공률
- 실패 확률
- 후속 보고 지연 일수
- 내부 노드 ID

## 4.5 `data/reports/` 규칙

포함 가능 정보:

- 보고 노드
- 보고 내용
- 대응 선택지
- 선택지별 다음 노드
- 선택지별 상태 수치 변화
- 선택지별 후속 보고 지연 범위
- 안정화 노드
- 격리 실패 노드
- 특수 이벤트 노드

주의:

- 이 데이터는 게임 내부 로직에 필요하지만 플레이어에게 그대로 보여주면 안 된다.
- 플레이어에게 보여줘도 되는 것은 보고 내용과 선택지 문장뿐이다.
- 내부 노드 ID, 상태 수치 변화, 후속 보고 지연 범위는 UI에 표시하지 않는다.

## 4.6 파일 이름 규칙

파일명은 단순한 개발용 ID를 사용한다.

```text
case_001_document.json
case_001_reports.json
case_014_document.json
case_014_reports.json
```

실제 플레이어에게 보여줄 식별명은 JSON 내부의 `display_id`에 저장한다.

```json
{
  "case_id": "case_001",
  "display_id": "CASE-XX(지명)-001",
  "alias": "돌아오는 길"
}
```

---

# 5. 저장/불러오기 구조

## 5.1 확정 방향

이 프로젝트는 자동 저장 구조를 사용한다.

수동 저장/불러오기 메뉴는 만들지 않는다.

저장 파일은 3개로 분리한다.

```text
user://current_run_save.json
user://archive_save.json
user://settings_save.json
```

## 5.2 `res://`와 `user://` 구분

| 경로 | 의미 |
|---|---|
| `res://` | 게임 프로젝트 안의 원본 파일 위치다. JSON 원본 데이터가 들어간다. |
| `user://` | 플레이어 컴퓨터에 저장되는 개인 저장 위치다. 실제 저장 파일이 들어간다. |

`res://data/`의 원본 JSON은 저장 과정에서 수정하지 않는다.

## 5.3 저장 파일별 역할

| 저장 파일 | 역할 |
|---|---|
| `current_run_save.json` | 현재 진행 중인 회차 정보를 저장한다. |
| `archive_save.json` | 회차가 끝나도 유지되는 기록 보관실 해금 정보를 저장한다. |
| `settings_save.json` | 볼륨, 전체 화면, 텍스트 크기 같은 설정값을 저장한다. |

## 5.4 저장 시점

- 하루 종료 시 자동 저장한다.
- 게임 종료 시 현재 회차가 진행 중이면 자동 저장한다.
- 설정은 설정 화면을 나갈 때 저장한다.

## 5.5 불러오기 시점

게임 실행 시 다음 순서로 처리한다.

1. `settings_save.json`을 불러온다.
2. `archive_save.json`을 불러온다.
3. `current_run_save.json` 존재 여부를 확인한다.

메인 메뉴에서 `근무 시작`을 누르면 다음과 같이 처리한다.

- 진행 중 회차가 있으면 이어서 진행한다.
- 진행 중 회차가 없으면 새 회차를 시작한다.

## 5.6 엔딩 시 저장 처리

### BAD 엔딩

1. 현재 회차에서 얻은 정보 중 50%를 보고 단위로 기록 보관실에 반영한다.
2. `archive_save.json`을 저장한다.
3. `current_run_save.json`을 삭제한다.
4. `settings_save.json`은 유지한다.

### GOOD 엔딩

1. 현재 회차에서 본 모든 보고/대응 정보를 기록 보관실에 반영한다.
2. `archive_save.json`을 저장한다.
3. `current_run_save.json`을 삭제한다.
4. `settings_save.json`은 유지한다.

## 5.7 저장 원칙

- 모든 저장 파일에는 `save_version`을 넣는다.
- 내부 수치는 저장 파일에 들어갈 수 있지만 UI에 직접 표시하지 않는다.
- BAD 엔딩이나 GOOD 엔딩으로 회차가 끝나면 `current_run_save.json`은 삭제한다.
- `archive_save.json`과 `settings_save.json`은 엔딩 이후에도 유지한다.

---

# 6. 하루 루프 구현 구조

## 6.1 확정 방향

하루 루프는 `day_manager.gd` 중심으로 구현하되, UI 흐름과 내부 계산 흐름을 분리한다.

하루 흐름은 다음과 같다.

```text
브리핑
→ 근무
→ 하루 종료
→ 다음 날 브리핑
```

하루 행동은 3회이며, 대응 선택지를 확정할 때만 1회 소모한다.

사용하지 않은 행동은 다음 날로 이월되지 않는다.

## 6.2 플레이어가 보는 흐름

```text
BriefingScreen
→ WorkScreen
→ ReportTab에서 보고서 확인
→ 대응 선택 및 확정
→ EndDayTab에서 하루 종료
→ 다음 날 BriefingScreen
```

## 6.3 내부 처리 원칙

- UI 스크립트는 화면 표시와 버튼 입력만 담당한다.
- 하루 종료 버튼이 눌리면 `end_day_tab.gd`는 `day_manager.gd`에 하루 종료를 요청한다.
- `day_manager.gd`가 하루 종료 처리 순서를 총괄한다.
- 세부 계산은 각 전용 매니저 스크립트가 나눠 맡는다.

## 6.4 확정 하루 종료 처리 순서

```text
1. 60일 생존 여부 확인
2. 오늘 처리한 보고서와 선택지 확정
3. 선택지에 따른 이상현상 상태 수치 변화 적용
4. 선택지에 따른 후속 보고 지연 일수 결정 및 예약
5. 오늘 처리하지 않은 보고서의 처리 지연 일수 증가
6. 처리 지연 보고서에 따른 이상현상 상태 수치 악영향 적용
7. 안정화된 이상현상의 안정화 후 경과일 증가
8. 안정화된 이상현상의 특수 이벤트 발생 판정
9. 특수 이벤트 발생 시 다음 날 브리핑에 표시될 보고로 등록
10. 관리 중인 이상현상들의 상태 수치를 기준으로 기관 신뢰도 계산
11. 기관 신뢰도 0 이하 여부 확인
12. 새 이상현상 추가 판정
13. 새 이상현상 추가 성공 시 관리 목록에 추가하고 첫 보고 생성
14. 다음 날 브리핑 내용 구성
15. 일차 증가
16. 다음 날 브리핑 화면으로 이동
```

## 6.5 중요 예외 규칙

60일차 하루 종료라면 가장 먼저 GOOD 엔딩을 판정한다.

GOOD 엔딩 조건을 만족하면 이후의 상태 계산, 기관 신뢰도 계산, 특수 이벤트 판정, 새 이상현상 추가 판정은 실행하지 않는다.

## 6.6 대응 확정 규칙

대응 확정 시에는 다음만 처리한다.

- 선택한 선택지 기록
- 해당 보고서를 당일 처리 완료 상태로 표시
- 잔여 대응 절차 1 감소
- 명령 접수 문구 표시
- `[처리 완료]` 도장 표시

선택지 효과 적용과 후속 보고 예약은 하루 종료 시 처리한다.

---

# 7. 첫 개발 범위

## 7.1 확정 방향

첫 개발 범위는 전체 게임 완성이 아니다.

가장 작은 실제 플레이 흐름을 먼저 구현한다.

```text
메인 메뉴
→ 브리핑 화면
→ 근무 화면
→ 보고서 1개 확인
→ 대응 선택
→ 대응 확정
→ 하루 종료
→ 다음 날 브리핑
```

## 7.2 첫 개발에 포함할 기능

| 대상 | 구현 내용 |
|---|---|
| `MainMenu.tscn` | 근무 시작, 기록 보관실, 설정, 근무 종료 버튼 배치 |
| `BriefingScreen.tscn` | 오늘 도착한 보고 요약 표시, 근무 시작 버튼 배치 |
| `WorkScreen.tscn` | 현재 일차, 잔여 대응 절차, 세 탭 표시 |
| `ReportTab.tscn` | 보고서 1개 목록/상세 표시, 대응 선택/확정 처리 |
| `EndDayTab.tscn` | 하루 종료 확인과 `day_manager.gd` 호출 |
| `day_manager.gd` | 일차 1 증가, 잔여 대응 절차 초기화, 다음 날 브리핑 이동 |
| `save_manager.gd` | 최소 저장 구조 준비 |

## 7.3 첫 개발에 포함하지 않을 기능

- 60일 전체 엔딩 완성
- BAD 엔딩 완성
- 기관 신뢰도 계산 완성
- 상태 수치 변화 완성
- 새 이상현상 추가 확률
- 특수 이벤트 판정
- 기록 보관실 해금 반영
- 여러 이상현상 동시 관리
- 여러 보고서 동시 처리
- 보고 루트 그래프 전체 구현
- Steam 업적
- 사운드/이미지 연출

## 7.4 첫 개발 원칙

- 테스트용 JSON은 기능 확인용이며 최종 콘텐츠가 아니다.
- Codex는 임의로 새 이상현상이나 보고서를 정식 콘텐츠로 추가하지 않는다.
- UI에는 내부 수치, 확률, 선택지 효과량, 후속 보고 지연 일수, 보고 노드 ID를 표시하지 않는다.
- UI 스크립트와 게임 로직 스크립트를 섞지 않는다.
- 원본 JSON은 수정하지 않고, 진행 상황은 `user://current_run_save.json`에 저장한다.

---

# 8. 개발 순서

## 8.1 확정 개발 순서

첫 개발은 보고서 1개를 처리하고 하루를 종료하는 최소 플레이 흐름을 구현하는 것을 목표로 한다.

개발 순서는 다음과 같다.

1. Godot 프로젝트 생성 및 확정 폴더 구조 만들기
2. 확정된 씬 구조에 따라 빈 씬 생성
3. `game_state.gd` 오토로드 생성
4. 기능 확인용 테스트 JSON 생성
5. `data_manager.gd`로 JSON 읽기 구현
6. `MainMenu.tscn`과 `main_menu.gd` 구현
7. `BriefingScreen.tscn`과 `briefing_screen.gd` 구현
8. `WorkScreen.tscn`과 세 탭 구조 구현
9. `ReportTab.tscn`에서 보고서 1개 표시 구현
10. 대응 선택과 대응 확정 구현
11. `EndDayTab.tscn`과 `day_manager.gd`를 연결해 하루 종료 흐름 구현
12. `save_manager.gd`로 최소 자동 저장 구현
13. 처음부터 끝까지 테스트하고 오류 수정

## 8.2 Codex 작업 단위

Codex에게는 한 번에 하나의 작은 작업만 지시한다.

추천 작업 단위:

1. 프로젝트 폴더 구조 생성
2. 빈 씬과 빈 스크립트 생성
3. `game_state.gd` 오토로드 생성
4. 테스트 JSON과 `data_manager.gd` 생성
5. `MainMenu` 화면 이동 구현
6. `BriefingScreen` 표시 구현
7. `WorkScreen` 탭 구조 구현
8. `ReportTab` 보고서 1개 표시 구현
9. 대응 선택과 확정 구현
10. `EndDayTab`과 `day_manager.gd` 하루 종료 흐름 구현
11. `save_manager.gd` 최소 저장 구현
12. 처음부터 끝까지 테스트하고 오류 수정

---

# 9. Codex/Godot 작업 시 지켜야 할 규칙

## 9.1 핵심 원칙

Codex는 개발 보조자이며, 기획자 역할을 대신하지 않는다.

Codex는 지시한 파일과 기능만 수정하고, 콘텐츠·밸런스·게임 구조는 임의로 바꾸지 않는다.

## 9.2 Codex 허용 작업

- 코드 구현
- 버그 수정
- 함수 정리
- 주석 추가
- 사용자가 제공한 데이터 삽입
- Godot 씬 연결 보조
- JSON 읽기 코드 작성
- 저장/불러오기 코드 작성
- UI 버튼 연결

## 9.3 Codex 금지 작업

- 지시하지 않은 사항에 대한 임의 수정
- 새 이상현상 임의 추가
- 새 보고 임의 작성
- 새 선택지 임의 작성
- 밸런스 수치 임의 변경
- 확률표 임의 변경
- 게임 구조 임의 변경
- 플레이어에게 내부 수치 표시
- 자원 분배, 전투, 직원 육성 시스템 추가
- SCP식 설정으로 방향 변경
- 수동 저장/불러오기 메뉴 임의 추가
- 회차 포기 기능 임의 추가

## 9.4 Godot 구현 규칙

- 씬은 확정된 `scenes/` 구조를 따른다.
- UI 스크립트는 `scripts/ui/`에 둔다.
- 게임 규칙 스크립트는 `scripts/game/`에 둔다.
- JSON 읽기는 `scripts/data/data_manager.gd`가 담당한다.
- 저장/불러오기는 `scripts/save/save_manager.gd`가 담당한다.
- 하루 종료 처리는 `scripts/game/day_loop/day_manager.gd`가 총괄한다.
- 원본 JSON은 `res://data/`에 둔다.
- 플레이어 저장 파일은 `user://`에 저장한다.
- UI 스크립트는 내부 계산을 직접 하지 않는다.
- 원본 JSON 데이터는 게임 진행 중 수정하지 않는다.

## 9.5 정보 비공개 규칙

플레이어 UI에 아래 정보를 표시하지 않는다.

- 확률
- 상태 수치
- 기관 신뢰도 수치
- 선택지 효과량
- 성공률
- 실패 확률
- 내부 계산식
- 보고 루트 노드 ID
- 후속 보고 지연 일수

## 9.6 Codex 작업 프롬프트 형식

Codex에게 작업을 맡길 때는 아래 형식을 사용한다.

```text
[작업 목표]
이번 작업에서 구현할 내용을 적는다.

[수정 허용 파일]
Codex가 수정해도 되는 파일만 적는다.

[수정 금지 파일]
Codex가 건드리면 안 되는 파일을 적는다.

[반드시 지킬 규칙]
내부 수치 비공개, JSON 임의 수정 금지, 구조 변경 금지 등을 적는다.

[완료 기준]
작업이 완료되었다고 판단할 조건을 적는다.
```

## 9.7 작업 진행 원칙

- 한 번에 하나의 작은 작업만 진행한다.
- 작업 범위 밖의 파일은 수정하지 않는다.
- 파일 이름이나 위치를 바꾸기 전에 먼저 확인한다.
- 테스트용 JSON은 기능 확인용이며 최종 콘텐츠가 아니다.
- 에러가 발생하면 Godot 오류 메시지를 그대로 확인한다.
- 각 작업은 실행 테스트 후 다음 단계로 넘어간다.

---

# 부록 A. 첫 개발 완료 기준

첫 개발은 아래 항목을 만족하면 완료로 본다.

1. 게임 실행 시 `MainMenu.tscn`이 열린다.
2. `근무 시작` 버튼을 누르면 `BriefingScreen.tscn`으로 이동한다.
3. 브리핑 화면에서 `근무 시작` 버튼을 누르면 `WorkScreen.tscn`으로 이동한다.
4. `WorkScreen.tscn`에서 세 탭을 전환할 수 있다.
5. `ReportTab.tscn`에 보고서 1개가 표시된다.
6. 보고서를 누르면 상세 내용이 표시된다.
7. 대응 선택지를 고를 수 있다.
8. 확정 전 선택지를 바꿀 수 있다.
9. 대응 확정 버튼을 누르면 잔여 대응 절차가 `3/3`에서 `2/3`으로 줄어든다.
10. 명령 접수 문구가 표시된다.
11. `[처리 완료]` 도장이 표시된다.
12. `EndDayTab.tscn`에서 하루 종료를 누르면 `day_manager.gd`가 실행된다.
13. 일차가 1 증가한다.
14. 잔여 대응 절차가 다시 `3/3`으로 초기화된다.
15. 다음 날 `BriefingScreen.tscn`으로 이동한다.
16. `current_run_save.json`이 저장된다.
17. 내부 수치가 화면에 표시되지 않는다.

---

# 부록 B. Codex 기본 작업 지시 템플릿

```text
당신은 Godot + GDScript 프로젝트 구현 보조자입니다.

기준 문서:
GAME_DESIGN_codex.md
GODOT_IMPLEMENTATION_PLAN.md

작업 목표:
[여기에 이번 작업 목표를 적는다]

수정 허용 파일:
[이번 작업에서 수정해도 되는 파일만 적는다]

수정 금지:
- 위에 적힌 파일 외에는 수정하지 마.
- data/anomalies/와 data/reports/의 콘텐츠를 임의로 추가하거나 수정하지 마.
- 새 이상현상, 새 보고서, 새 선택지를 임의 작성하지 마.
- 밸런스 수치, 확률, 상태 수치 효과량을 임의 변경하지 마.
- 게임 구조를 임의 변경하지 마.
- 플레이어 UI에 내부 수치, 확률, 선택지 효과량, 보고 노드 ID, 후속 보고 지연 일수를 표시하지 마.
- 자원 분배, 전투, 직원 육성 시스템을 추가하지 마.
- 수동 저장/불러오기, 회차 포기 기능을 임의 추가하지 마.

구현 규칙:
- UI 코드는 scripts/ui/에 둔다.
- 게임 규칙 코드는 scripts/game/에 둔다.
- JSON 읽기는 scripts/data/data_manager.gd가 담당한다.
- 저장은 scripts/save/save_manager.gd가 담당한다.
- 하루 종료 처리는 scripts/game/day_loop/day_manager.gd가 총괄한다.
- 원본 JSON은 res://data/에 두고, 저장 파일은 user://에 저장한다.

완료 기준:
[이번 작업이 완료되었다고 판단할 조건을 적는다]
```
