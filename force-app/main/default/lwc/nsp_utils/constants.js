const CLASS_BY_ORDER = {
  1: "level-1",
  2: "level-2",
  3: "level-3",
  4: "level-4",
};
const SELECTION_BOX = "C-NSP_SELECTION-BOX";
const ANSWERED_CLASS_NAME = "answered";
const RL_CLASS_NAME = "redAnswered";
const LABEL_CLASSES = [ ANSWERED_CLASS_NAME, RL_CLASS_NAME ];
const SYNC_FIELD_EVENT_NAME = "syncfields";
const RL_FIELD_ACCEPTED_VALUES = [
  "Requested",
  "Requested - Not Collected",
  "Requested - Not collected",
];

export {
  CLASS_BY_ORDER,
  SELECTION_BOX,
  ANSWERED_CLASS_NAME,
  RL_CLASS_NAME,
  LABEL_CLASSES,
  SYNC_FIELD_EVENT_NAME,
  RL_FIELD_ACCEPTED_VALUES,
};
