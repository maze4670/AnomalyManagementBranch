# CONTENT_INTEGRATION_GUIDE.md

## 1. 문서 목적

이 문서는 이상현상 제작 규칙이 아니다.

이 문서는 정식 이상현상 콘텐츠를 게임 프로젝트에 투입할 때의 구현/변환 기준을 정리한다.

이 문서는 아래를 다루지 않는다.

- 이상현상을 어떻게 창작할 것인가
- 세계관 규칙을 어떻게 만들 것인가
- 보고서 문체를 어떻게 새로 설계할 것인가
- 새 이상현상 아이디어를 어떻게 생성할 것인가
- 새 사건, 새 보고, 새 선택지를 어떻게 창작할 것인가

이 문서는 아래를 다룬다.

- 사용자가 이미 작성하거나 승인한 정식 이상현상 콘텐츠를 JSON 구조로 옮기는 방법
- Codex가 승인되지 않은 콘텐츠를 임의로 추가하지 못하게 하는 제한
- 테스트 데이터와 정식 콘텐츠를 구분하는 기준
- 내부 수치와 내부 ID가 UI에 노출되지 않도록 하는 기준

## 2. 다른 기획 문서와의 역할 구분

이 문서는 프로젝트의 창작 규칙을 대체하지 않는다.

이상현상 제작 규칙, 세계관 규칙, containment 철학, 사례 설계 원칙은 별도의 기획 문서에서 다룬다.

이 문서는 구현 단계 문서다.

역할 구분:

- CORE_PHILOSOPHY / WORLD_RULES / CASE_DESIGN_RULES 계열 문서
  - 이상현상과 세계관을 어떻게 설계할지 다루는 창작/기획 기준
- GAME_DESIGN_codex.md
  - 현재 게임의 확정 기획 기준
- GODOT_IMPLEMENTATION_PLAN.md
  - Godot 구현 구조 기준
- CONTENT_INTEGRATION_GUIDE.md
  - 이미 승인된 콘텐츠를 JSON 데이터로 변환하고 게임에 넣는 기준

Codex는 CONTENT_INTEGRATION_GUIDE.md를 근거로 새 콘텐츠를 창작하면 안 된다.

## 3. 현재 테스트 데이터의 지위

아래 데이터는 기능 확인용 테스트 데이터다.

- case_001
- case_002
- case_pool.json
- special_event_rules.json

이 데이터는 아래에 해당하지 않는다.

- 정식 이상현상 콘텐츠
- 정식 보고서 콘텐츠
- 정식 선택지 콘텐츠
- 정식 밸런스
- 정식 등장 구조
- 정식 특수 이벤트 구조

Codex는 현재 테스트 데이터를 정식 세계관 설정으로 확정하면 안 된다.
Codex는 테스트 데이터의 문장, 보고 내용, 선택지, state_delta, delay_range를 정식 콘텐츠나 정식 밸런스로 간주하면 안 된다.

## 4. 정식 콘텐츠 투입 원칙

정식 이상현상 콘텐츠는 사용자가 직접 제공하거나 명시적으로 승인한 내용만 사용한다.

Codex는 아래 내용을 임의로 만들 수 없다.

- 새 이상현상
- 새 별칭
- 새 display_id
- 새 category
- 새 basic_description
- 새 additional_descriptions
- 새 보고서 본문
- 새 선택지 문구
- 새 후속 보고
- 새 특수 이벤트
- 새 엔딩 문구
- 새 기록 보관실 설명 문구

Codex가 할 수 있는 일은 다음으로 제한된다.

- 사용자가 제공한 원문을 JSON 구조에 맞게 정리
- 누락된 필드 확인
- 내부 ID 형식 제안
- 기획 문서와 충돌하는 부분 점검
- 승인된 내용을 기존 데이터 구조에 맞게 변환

부족한 필드가 있으면 Codex가 임의로 채우지 말고 사용자에게 확인해야 한다.

## 5. 정식 이상현상 JSON 변환 기준

정식 이상현상 문서는 아래 구조를 따른다.

대상 파일 예:

- data/anomalies/{case_id}_document.json

필수 필드:

- case_id
- display_id
- alias
- category
- basic_description
- additional_descriptions

테스트 데이터에서는 아래 필드를 유지할 수 있다.

- is_test_data
- note

정식 콘텐츠로 전환할 때는 is_test_data와 note를 제거하거나 사용하지 않을 수 있다.

단, 테스트 데이터가 정식 콘텐츠로 전환되기 전까지는 is_test_data와 note를 유지한다.

Codex는 정식 이상현상 문서의 내용을 임의로 확장하거나 각색하면 안 된다.

## 6. 정식 보고서 JSON 변환 기준

보고서 파일은 아래 구조를 따른다.

대상 파일 예:

- data/reports/{case_id}_reports.json

필수 필드:

- case_id
- start_node_id
- nodes

각 node 필수 필드:

- node_id
- report_day_label
- report_text
- choices

각 choice 필수 필드:

- choice_id
- choice_text
- next_node_id
- state_delta
- delay_range

중요:

- node_id, choice_id, next_node_id는 내부 처리용이다.
- state_delta와 delay_range는 내부 계산용이다.
- 이 값들은 UI에 표시하면 안 된다.
- Codex는 state_delta와 delay_range 값을 임의로 정식 밸런스로 확정하면 안 된다.
- 정식 밸런스 수치는 사용자가 승인해야 한다.

보고서 본문과 선택지 문구는 사용자가 제공하거나 승인한 내용만 사용한다.

Codex는 보고서 본문을 새로 쓰거나, 선택지를 임의로 추가하거나, 후속 보고를 임의로 만들면 안 된다.

## 7. UI 표시 가능 정보와 금지 정보

UI에 표시 가능한 정보:

- display_id
- alias
- category
- basic_description
- additional_descriptions
- report_day_label
- report_text
- choice_text

UI에 표시 금지:

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
- is_test_data
- note

위 값들은 내부 저장과 계산에는 사용할 수 있지만 플레이어 UI에는 표시하지 않는다.

## 8. 기록 보관실 표시 규칙

기록 보관실은 플레이어에게 현재 열람 가능한 기록만 보여준다.

기록 보관실 UI에는 아래 문구를 표시하지 않는다.

- 해금됨
- 일부 기록
- 전체 기록
- 갱신됨
- 해금 상태
- 회차 종료 후 기록이 보관된다는 설명
- 기록이 추가되었다는 설명
- 시스템 처리 상태 설명

archive_save 내부의 아래 값은 UI에 표시하지 않는다.

- unlock_level
- unlocked_report_keys
- endings_seen
- partial
- full

기록 목록에는 display_id / alias만 표시한다.

상세에는 공개 문서 정보와 열람 가능한 보고 기록만 표시한다.

## 9. case_pool 전환 기준

현재 case_pool.json은 기능 확인용 테스트 데이터다.

정식 콘텐츠 투입 시:

- starting_cases는 사용자가 승인한 초기 등장 이상현상만 포함한다.
- introducible_cases는 사용자가 승인한 추가 등장 후보만 포함한다.
- 등장 확률, 등장 조건, 밸런스 수치는 Codex가 임의로 만들지 않는다.
- case_pool은 정식 전환 전까지 테스트 구조로 유지한다.

Codex는 case_pool에 새 case를 임의로 추가하면 안 된다.

## 10. special_event_rules 전환 기준

현재 special_event_rules.json은 기능 확인용 내부 판정 규칙이다.

정식 특수 이벤트 투입 전까지 아래를 만들지 않는다.

- 이벤트 문구
- 이벤트 UI
- 브리핑 이벤트 표시
- 이벤트 선택지
- 이벤트 결과
- 이벤트 보상
- 이벤트 패널티
- 정식 사건 내용

정식 특수 이벤트는 사용자가 별도로 승인한 후에만 추가한다.

Codex는 특수 이벤트를 임의로 창작하면 안 된다.

## 11. 정식 콘텐츠 교체 절차

정식 콘텐츠 교체는 아래 절차를 따른다.

1. 사용자가 정식 이상현상 원문 또는 설계안을 제공한다.
2. ChatGPT가 GAME_DESIGN_codex.md 기준으로 충돌 여부를 검토한다.
3. 필요한 필드가 부족하면 사용자에게 질문한다.
4. 사용자가 승인한 내용만 JSON 변환 대상으로 삼는다.
5. Codex는 승인된 내용을 기준으로 JSON 파일을 수정한다.
6. Godot에서 보고서 표시, 선택지 처리, 하루 종료, 저장/불러오기, 기록 보관실을 테스트한다.
7. 문제가 없으면 Git에 저장한다.

이 절차 전에는 테스트 데이터를 정식 콘텐츠로 교체하지 않는다.

## 12. Codex 작업 제한

Codex는 아래 작업을 임의로 하면 안 된다.

- 새 이상현상 창작
- 새 보고서 본문 창작
- 새 선택지 문구 창작
- 새 특수 이벤트 창작
- 새 엔딩 문구 창작
- 새 기록 보관실 설명 문구 창작
- UI에 시스템 설명 문구 추가
- 해금 상태 문구 추가
- 내부 수치 표시
- 정식 밸런스 수치 결정
- 등장 확률 결정
- 기획 문서에 없는 기능 추가
- 테스트 데이터를 정식 콘텐츠로 확정
- 사용자가 승인하지 않은 문장 추가

Codex는 구현 보조자이며, 기획자나 콘텐츠 창작자가 아니다.

## 13. 다음 단계

다음 단계는 사용자가 실제 정식 이상현상 후보 1개를 제공하거나,
기존에 작성해둔 이상현상 설계 문서 중 하나를 선택하는 것이다.

그 전까지 Codex는 테스트 데이터를 정식 콘텐츠로 교체하지 않는다.
