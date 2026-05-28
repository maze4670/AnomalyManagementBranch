# IMPLEMENTATION_STATUS.md

## 1. 문서 목적

이 문서는 현재 Godot 프로젝트의 구현 상태를 정리하는 문서다.

이 문서는 기획을 변경하기 위한 문서가 아니다. 현재까지 구현된 기능, 아직 구현하지 않은 기능, 기획상 구현하지 않는 기능, 다음 개발 단계로 넘어가기 전 확인할 사항을 기록한다.

## 2. 기준 문서

- GAME_DESIGN_codex.md
- GODOT_IMPLEMENTATION_PLAN.md
- IMPLEMENTATION_STATUS.md

## 3. 현재 구현 완료 상태

아래 항목이 구현 완료되었다.

- Godot 프로젝트 생성
- Git / GitHub 연결
- 기준 문서 추가
- 확정 폴더 구조 생성
- 빈 씬 / 빈 스크립트 생성
- GameState 오토로드 생성
- 테스트 JSON 생성
- DataManager 최소 JSON 읽기 구현
- MainMenu 화면 이동 구현
- BriefingScreen 표시와 WorkScreen 이동 구현
- WorkScreen 탭 구조 구현
- ReportTab에서 테스트 보고서 표시
- ReportTab이 active_reports 배열 기준으로 여러 보고서를 표시할 수 있도록 안정화됨
- active_reports에 여러 보고서가 있어도 각 보고서가 독립적으로 선택/상세 표시/대응 확정될 수 있음
- 보고서별 처리 완료 상태가 case_id:node_id 기준으로 독립 관리됨
- 보고서별 처리 지연 상태가 case_id:node_id 기준으로 독립 관리됨
- case_001과 case_002가 동시에 존재해도 서로 잘못 처리 완료되지 않음
- 대응 선택 기능 구현
- 대응 확정 기능 구현
- 잔여 대응 절차 감소 구현
- [처리 완료] 표시 구현
- [처리 지연] 라벨 표시 구현
- 최소 하루 종료 흐름 구현
- 최소 current_run_save.json 자동 저장 구현
- 최소 current_run_save.json 불러오기 구현
- 메인 메뉴의 근무 시작 버튼에서 저장 파일 자동 이어하기 구현
- 저장 파일이 없을 경우 새 회차 초기화 구현
- completed_reports 저장/불러오기 구현
- active_reports 저장/불러오기 구현
- scheduled_reports 저장/불러오기 구현
- pending_completed_choices 저장/불러오기 구현
- delayed_reports 저장/불러오기 구현
- anomaly_states 내부 상태 저장 구조 구현
- case_001과 case_002의 anomaly_states가 각각 독립적으로 저장/계산됨
- 선택지 state_delta를 하루 종료 시 anomaly_states에 적용하는 최소 구조 구현
- 처리 지연 악영향 최소 구조 구현
- 처리 지연 단계별 중복 적용 방지용 applied_delay_penalties 구현
- applied_delay_penalties 저장/불러오기 구현
- anomaly_states 기준 trust_value 내부 계산 최소 구조 구현
- trust_manager.gd의 최소 신뢰도 계산 함수 구현
- trust_value 저장/불러오기 구현
- BAD 엔딩 최소 판정 구조 구현
- trust_value가 0 이하일 때 BAD 엔딩으로 이동
- BAD 엔딩 시 current_run_save.json 삭제
- GOOD 엔딩 최소 판정 구조 구현
- current_day가 60 이상일 때 GOOD 엔딩으로 이동
- GOOD 엔딩은 하루 종료 처리의 가장 처음에 판정됨
- GOOD 엔딩 시 current_run_save.json 삭제
- EndingScreen에서 GOOD/BAD 문구 구분 표시 구현
- data/anomalies/case_002_document.json 추가
- data/reports/case_002_reports.json 추가
- case_002는 기능 확인용 테스트 데이터이며 정식 콘텐츠가 아님
- case_002의 문장, 보고 내용, 선택지, state_delta는 기능 확인용 더미 데이터이며 정식 밸런스/콘텐츠가 아님
- Codex는 case_002를 정식 이상현상으로 확정하거나 확장하지 않음
- 새 회차 시작 시 기본 active_reports에는 case_001만 들어오도록 변경됨
- 하루 종료 후 내부 판정으로 case_002 첫 보고가 추가되는 최소 구조 구현
- known_cases로 현재 회차에 등장한 case_id를 추적함
- known_cases 저장/불러오기 구현
- case_002가 이미 known_cases에 있으면 중복 추가되지 않음
- 새 이상현상 추가 판정은 기능 확인용 최소 구조이며 정식 등장 조건/확률/밸런스가 아님
- UI에는 “새 이상현상 추가”, “갱신됨”, “추가됨” 같은 시스템 문구를 표시하지 않음
- data/system/case_pool.json 추가
- starting_cases와 introducible_cases를 통해 테스트 case 목록을 데이터 파일로 분리함
- DataManager에 load_case_pool() 구현
- GameState의 기본 active_reports와 anomaly_states가 case_pool 기준으로 구성됨
- get_next_test_case_to_introduce()가 case_pool의 introducible_cases 기준으로 작동함
- case_pool.json은 기능 확인용 테스트 데이터이며 정식 콘텐츠 투입 구조가 아님
- case_pool에는 현재 case_001과 case_002만 포함됨
- 정식 등장 확률이나 정식 밸런스 수치는 포함하지 않음
- 후속 보고 예약 최소 구조 구현
- scheduled_reports의 days_remaining 감소 처리 구현
- 도착한 후속 보고를 active_reports로 이동하는 최소 구조 구현
- BriefingScreen이 active_reports 기준으로 브리핑 문구를 동적으로 표시하도록 수정
- 신규 보고와 처리 지연 보고를 구분하는 브리핑 표시 구현
- active_reports가 없으면 “금일 신규 보고는 없습니다.” 표시
- ArchiveScreen 기본 화면 구현
- archive_save.json 최소 구조 구현
- 엔딩 후 archive_save 반영 최소 구조 구현
- archive_save가 여러 case_id를 처리할 수 있도록 안정화됨
- completed_reports에 여러 case_id가 있을 경우 case_id별로 archive_save에 반영 가능
- ArchiveScreen이 archive_save의 여러 case_id를 목록에 표시할 수 있음
- 기록 목록은 display_id / alias만 표시함
- 기록 상세는 공개 문서 정보와 열람 가능한 보고 기록만 표시함
- 기록 보관실 UI에는 해금 상태, 일부 기록, 전체 기록, 갱신됨 같은 시스템 문구를 표시하지 않음
- 내부 unlock_level, unlocked_report_keys, partial, full은 UI에 표시하지 않음
- 기록 보관실 UI에는 현재 열람 가능한 기록만 표시함
- SettingsScreen 기본 UI 구현
- 전체 볼륨, 화면 모드, 텍스트 크기 항목 표시 구현
- 설정 화면 UI 상호작용 구현
- settings_save.json 저장/불러오기 구현
- volume, screen_mode, text_size 저장/불러오기 구현
- 화면 모드 실제 적용 코드 준비
- Master 볼륨 실제 적용 구현
- 텍스트 크기 설정 화면 미리보기 구현
- 게임 전체 UI 텍스트 크기 적용은 아직 구현하지 않음

## 4. 현재 가능한 플레이 흐름

현재 가능한 플레이 흐름은 다음과 같다.

메인 메뉴
→ 근무 시작
→ current_run_save.json이 있으면 저장된 회차 상태 자동 적용
→ current_run_save.json이 없으면 새 회차 시작
→ case_pool의 starting_cases 기준으로 case_001 첫 보고만 도착
→ 브리핑에서 active_reports 기준 보고 도착 여부 표시
→ 근무 화면
→ ReportTab에서 active_reports 기준 보고서 표시
→ 보고서 선택
→ 대응 선택
→ 대응 확정
→ 처리 완료 기록
→ 선택지 state_delta 내부 적용 준비
→ 후속 보고 예약 준비
→ 하루 종료
→ 미처리 보고서 처리 지연 증가
→ 처리 지연 악영향 내부 적용
→ 선택지 state_delta 내부 적용
→ 후속 보고 예약 처리
→ scheduled_reports 도착 처리
→ anomaly_states 갱신
→ trust_value 내부 계산
→ GOOD/BAD 엔딩 조건 확인
→ 엔딩이 없으면 case_pool의 introducible_cases 기준으로 case_002 첫 보고 추가
→ case_002는 known_cases에 기록되어 중복 추가되지 않음
→ current_run_save.json 저장 후 다음 날 브리핑
→ 이후 case_001과 case_002 보고서가 독립적으로 처리/지연/저장됨
→ 엔딩 발생 시 archive_save에 여러 case_id 기록 반영 가능
→ 기록 보관실에서 여러 case의 목록과 상세 표시 가능

## 5. 첫 개발 범위 완료 판단

현재 구현은 초기의 “보고서 1개 처리 + 하루 종료” 범위를 넘어, 최소 저장/불러오기, 보고서 처리 완료 상태 유지, 후속 보고 예약, 처리 지연, 처리 지연 악영향, 내부 상태 수치, 기관 신뢰도 내부 계산, GOOD/BAD 엔딩 최소 구조까지 구현된 상태다.

또한 다중 보고서, 기능 확인용 다중 이상현상, 새 이상현상 추가 판정 최소 구조, case_pool 데이터 분리, 다중 case archive 반영까지 검증된 상태다.

다만 이는 여전히 기능 확인용 테스트 구조이며, 정식 콘텐츠 투입, 정식 등장 조건, 정식 밸런스, 최종 기록 보관실 UI, 특수 이벤트, Steam 업적, 최종 연출은 아직 구현되지 않았다.

## 6. 아직 구현하지 않은 기능

아래 항목은 아직 구현하지 않았으며, 사용자의 별도 지시 없이 Codex가 임의로 추가하면 안 된다.

- 실제 이상현상 콘텐츠
- 정식 보고서 콘텐츠
- 정식 선택지 콘텐츠
- 정식 등장 조건 / 등장 확률 / 밸런스
- 특수 이벤트 판정 구조
- 기록 보관실 최종 UI 디자인
- 기록 보관실 상세 문서 최종 레이아웃
- 설정값의 게임 전체 텍스트 크기 적용
- Steam 업적
- 사운드/이미지 연출
- 최종 UI 디자인 정리
- Windows 빌드/export 테스트
- Steam 배포 준비

아래 항목은 기능 확인용 최소 구조만 구현 완료된 상태다. 정식 콘텐츠/최종 구조/최종 UI는 아직 미완성이다.

- 여러 보고서 동시 처리
- 여러 이상현상 동시 관리
- 새 이상현상 추가 판정
- 기록 보관실 해금 반영
- 엔딩 후 archive_save 반영
- 후속 보고 예약
- 선택지 효과 적용
- 상태 수치 변화
- 처리 지연 악영향
- 기관 신뢰도 계산
- GOOD/BAD 엔딩

## 7. 기획상 구현하지 않는 기능

아래 항목은 현재 기획에서 제외된 기능이며, Codex가 임의로 추가하면 안 된다.

- 수동 저장/불러오기 UI
- 회차 포기 기능
- 자원 분배 시스템
- 전투 시스템
- 직원 육성 시스템
- SCP식 설정 복붙 구조

## 8. 현재 테스트 데이터 주의

현재 case_001 관련 JSON은 기능 확인용 테스트 데이터이며 정식 콘텐츠가 아니다.

현재 case_002 관련 JSON도 기능 확인용 테스트 데이터이며 정식 콘텐츠가 아니다.

case_pool.json은 기능 확인용 테스트 case 목록이며 정식 콘텐츠 투입 구조가 아니다.

case_001_reports.json과 case_002_reports.json의 보고 노드, 후속 보고 노드, 선택지, state_delta는 기능 확인용 테스트 데이터다.

state_delta, delay_penalty_delta, trust_value 계산식은 기능 확인용 최소 구조이며 정식 밸런스가 아니다.

Codex는 테스트 데이터를 정식 콘텐츠나 정식 밸런스로 확정하지 않는다.

## 9. 정보 비공개 확인

아래 정보는 내부 저장/계산에는 사용할 수 있지만 UI에는 표시하지 않는다.

- case_pool
- known_cases
- node_id
- choice_id
- next_node_id
- state_delta
- delay_range
- delay_days 숫자
- anomaly_states
- trust_value
- applied_delay_penalties
- unlock_level
- unlocked_report_keys
- endings_seen
- partial
- full
- 확률
- 상태 수치
- 기관 신뢰도 수치
- 선택지 효과량
- 내부 계산식

## 10. 다음 개발 단계 후보

다음 개발 단계 후보는 아래 중에서 사용자가 선택한다.

1. 현재 구현 리팩터링 및 안정화
2. 특수 이벤트 판정 최소 구조 구현
3. 테스트 데이터를 정식 콘텐츠 구조로 교체하기 위한 설계
4. 실제 이상현상 콘텐츠 1개 작성 및 테스트 데이터 교체
5. 기록 보관실 상세 UI 최종 레이아웃 정리
6. 설정값의 전체 UI 텍스트 크기 적용 검토
7. Windows export 빌드 테스트
8. 최종 UI 레이아웃 정리
