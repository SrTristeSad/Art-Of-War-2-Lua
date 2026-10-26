-- Animation frame manifest for explicitly verified J2ME animation sequences.
-- IMPORTANT: The PNG matches in atlas_catalog.lua prove pixel identity only.
-- Do not add frames to this table until frame order, source rectangles and FPS
-- have been checked against the original runtime/JAR, with evidence recorded.
-- Example shape (NOT an actual active sequence):
-- blue_infantry={walk={fps=8,verification='verified',frames={
--   {atlas='i0_8_77x152.png',x=0,y=0,w=15,h=17}, ...}}}
return {}
