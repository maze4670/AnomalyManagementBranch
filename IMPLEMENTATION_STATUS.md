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
- ReportTab에서 테스트 보고서 1개 표시
- 대응 선택 기능 구현
- 대응 확정 기능 구현
- 잔여 대응 절차 감소 구현
- [처리 완료] 표시 구현
- 최소 하루 종료 흐름 구현
- 최소 current_run_save.json 자동 저장 구현
- 최소 current_run_save.json 불러오기 구현
- 메인 메뉴의 근무 시작 버튼에서 저장 파일 자동 이어하기 구현
- 저장 파일이 없을 경우 새 회차 초기화 구현
- 보고서 처리 완료 상태 GameState 기록 구현
- completed_reports 저장/불러오기 구현
- 이미 처리 완료된 보고서 재확정 방지 구현
- 처리 완료된 보고서의 [처리 완료] 표시 유지 구현
- 이전에 선택한 선택지 하이라이트 유지 구현
- 테스트 보고서 기준 후속 보고 노드 추가
- 대응 확정 시 후속 보고 예약 준비 정보 기록 구현
- pending_completed_choices 상태 저장/불러오기 구현
- active_reports 상태 저장/불러오기 구현
- scheduled_reports 상태 저장/불러오기 구현
- 하루 종료 시 후속 보고 예약 처리 구현
- scheduled_reports의 days_remaining 감소 처리 구현
- 도착한 후속 보고를 active_reports로 이동하는 최소 구조 구현
- ReportTab이 active_reports 기준으로 보고서 목록을 표시하도록 수정
- active_reports가 비어 있으면 “현재 도착한 보고가 없습니다.” 표시 구현
- BriefingScreen이 active_reports 기준으로 브리핑 문구를 동적으로 표시하도록 수정
- active_reports가 있으면 신규 보고 접수 문구 표시
- active_reports가 없으면 “금일 신규 보고는 없습니다.” 표시
- 신규 보고와 처리 지연 보고를 구분하는 브리핑 표시 구현
- 3일차, 4일차처럼 도착 보고가 없는 날에 신규 보고 문구가 표시되지 않도록 수정
- delayed_reports 기반 처리 지연 상태 기록 구현
- [처리 지연] 라벨 표시 구현
- 처리 지연 악영향 최소 구조 구현
- 처리 지연 단계별 중복 적용 방지용 applied_delay_penalties 구현
- applied_delay_penalties 저장/불러오기 구현
- anomaly_states 내부 상태 저장 구조 구현
- 선택지 state_delta를 하루 종료 시 anomaly_states에 적용하는 최소 구조 구현
- anomaly_states 저장/불러오기 구현
- anomaly_states와 상태 수치는 내부 계산용이며 UI에 표시하지 않음
- anomaly_states 기준 trust_value 내부 계산 최소 구조 구현
- trust_manager.gd의 최소 신뢰도 계산 함수 구현
- trust_value 저장/불러오기 구현
- 기관 신뢰도 수치와 계산식은 UI에 표시하지 않음
- 현재 신뢰도 계산식은 기능 확인용 최소 구조이며 정식 밸런스 확정이 아님
- BAD 엔딩 최소 판정 구조 구현
- trust_value가 0 이하일 때 BAD 엔딩으로 이동
- BAD 엔딩 시 current_run_save.json 삭제
- GOOD 엔딩 최소 판정 구조 구현
- current_day가 60 이상일 때 GOOD 엔딩으로 이동
- GOOD 엔딩은 하루 종료 처리의 가장 처음에 판정됨
- GOOD 엔딩 시 current_run_save.json 삭제
- EndingScreen에서 GOOD/BAD 문구 구분 표시 구현
- GOOD/BAD 엔딩 모두 기록 보관실 반영은 아직 구현하지 않음
- 엔딩 화면에는 내부 수치나 계산식을 표시하지 않음
- ArchiveScreen 기본 화면 구현
- 기록 보관실 제목 표시
- 아직 해금된 기록이 없다는 안내 표시
- 메인 메뉴로 돌아가기 구현
- archive_save.json과 기록 해금 기능은 아직 구현하지 않음
- SettingsScreen 기본 UI 구현
- 전체 볼륨, 화면 모드, 텍스트 크기 항목 표시 구현
- 제작진 문구 표시 구현
- 설정 화면 UI 상호작용 구현
- 전체 볼륨 슬라이더 값 표시 구현
- 화면 모드 버튼의 창 모드 / 전체 화면 상태 전환 구현
- 텍스트 크기 버튼의 작게 / 보통 / 크게 상태 전환 구현
- settings_save.json 저장/불러오기 구현
- volume, screen_mode, text_size 저장/불러오기 구현
- 화면 모드 실제 적용 코드 준비
- Godot 에디터의 embedded window 실행 환경에서는 전체 화면 검증이 제한될 수 있음
- Master 볼륨 실제 적용 구현
- 텍스트 크기 설정 화면 미리보기 구현
- 게임 전체 UI 텍스트 크기 적용은 아직 구현하지 않음
- 첫 개발 흐름 전체 테스트 완료

## 4. 현재 가능한 플레이 흐름

현재 가능한 플레이 흐름은 다음과 같다.

메인 메뉴
→ 근무 시작
→ current_run_save.json이 있으면 저장된 회차 상태 자동 적용
→ current_run_save.json이 없으면 새 회차 시작
→ 브리핑
→ active_reports 기준 보고 도착 여부 표시
→ 신규 보고와 처리 지연 보고 구분 표시
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
→ anomaly_states 갱신
→ trust_value 내부 계산
→ GOOD/BAD 엔딩 조건 확인
→ 엔딩 조건이 없으면 current_run_save.json 저장 후 다음 날 브리핑으로 이동
→ 엔딩 조건이 있으면 EndingScreen으로 이동하고 current_run_save.json 삭제

## 5. 첫 개발 범위 완료 판단

현재 구현은 “보고서 1개 처리 + 하루 종료까지의 최소 실제 플레이 흐름”을 넘어, 최소 저장/불러오기, 보고서 처리 완료 상태 유지, 후속 보고 예약, 처리 지연, 처리 지연 악영향, 내부 상태 수치, 기관 신뢰도 내부 계산, GOOD/BAD 엔딩 최소 구조까지 구현된 상태다.

다만 여전히 전체 게임 완성이 아니며, 정식 콘텐츠, 여러 보고서/여러 이상현상 구조, 기록 보관실 해금, 엔딩 후 archive_save 반영, Steam 업적, 최종 UI/연출은 아직 구현되지 않았다.

선택지 효과 적용, 상태 수치 변화, 처리 지연 악영향, 기관 신뢰도 계산, GOOD/BAD 엔딩은 최소 구조 구현 완료 상태다. 그러나 정식 밸런스, 최종 연출, 확장 구조는 아직 미완성이다.

## 6. 아직 구현하지 않은 기능

아래 항목은 아직 구현하지 않았으며, 사용자의 별도 지시 없이 Codex가 임의로 추가하면 안 된다.

- 실제 이상현상 콘텐츠
- 여러 보고서 동시 처리
- 여러 이상현상 동시 관리
- 새 이상현상 추가 판정
- 특수 이벤트 판정
- 기록 보관실 해금 반영
- 엔딩 후 archive_save 반영
- GOOD 엔딩 기록 전체 반영
- BAD 엔딩 기록 50% 반영
- 설정값의 게임 전체 텍스트 크기 적용
- 기록 보관실 상세 문서 화면
- Steam 업적
- 사운드/이미지 연출
- 최종 UI 디자인 정리

후속 보고 예약, 선택지 효과 적용, 상태 수치 변화, 처리 지연 악영향, 기관 신뢰도 계산, GOOD/BAD 엔딩은 테스트 보고서 기준 최소 구조만 구현된 상태다. 정식 다중 보고/다중 이상현상 구조, 정식 밸런스, 최종 연출은 아직 구현되지 않았다.

## 7. 기획상 구현하지 않는 기능

아래 항목은 현재 기획에서 제외된 기능이며, Codex가 임의로 추가하면 안 된다.

- 수동 저장/불러오기 UI
- 회차 포기 기능
- 자원 분배 시스템
- 전투 시스템
- 직원 육성 시스템
- SCP식 설정 복붙 구조

## 8. 현재 테스트 데이터 주의

현재 case_001 관련 JSON은 기능 확인용 테스트 데이터다.

이 데이터는 정식 이상현상 콘텐츠가 아니다. Codex는 이를 정식 콘텐츠로 확정하거나 확장하지 않는다.

case_001_reports.json의 보고 노드, 후속 보고 노드, 선택지, state_delta는 기능 확인용 테스트 데이터다.

state_delta와 처리 지연 악영향 수치는 기능 확인용 최소값이며 정식 밸런스 수치가 아니다. Codex는 이를 정식 콘텐츠나 정식 밸런스로 확정하지 않는다.

## 9. 정보 비공개 확인

현재 UI에는 아래 정보가 표시되지 않아야 한다.

- node_id
- choice_id
- next_node_id
- state_delta
- delay_range
- delay_days 숫자
- anomaly_states
- trust_value
- applied_delay_penalties
- 확률
- 상태 수치
- 기관 신뢰도 수치
- 선택지 효과량
- 후속 보고 지연 일수
- 내부 계산식

위 값들은 내부 저장과 계산에는 사용할 수 있지만 UI에는 표시하지 않는다.

## 10. 다음 개발 단계 후보

다음 개발 단계 후보는 아래 중에서 사용자가 선택한다.

1. 현재 구현 리팩터링 및 안정화
2. 여러 보고서 / 여러 이상현상 구조 확장
3. 기록 보관실 해금 및 archive_save 구조 구현
4. 엔딩 후 기록 보관실 반영 구조 구현
5. 새 이상현상 추가 판정 구조 구현
6. 특수 이벤트 판정 구조 구현
7. 설정값의 전체 UI 텍스트 크기 적용 검토
8. 테스트 JSON을 실제 콘텐츠 구조로 교체하기 위한 준비
9. 최종 UI 레이아웃 정리
