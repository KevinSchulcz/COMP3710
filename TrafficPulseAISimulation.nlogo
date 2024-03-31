globals [
  crossing-ped-x?
  crossing-ped-y?
  crossing-car-x?
  crossing-car-y?
  ped-x-updated?
  ped-y-updated?
  car-x-updated?
  car-y-updated?
  temp-var
  cpp-next-car
  cpp-total-cars
  fcfs-next-agent
  fcfs-total-agents
  average-pedestrian-trip-time
  average-car-trip-time
  total-pedestrian-trip-time
  total-car-trip-time
  total-pedestrians
  total-cars
]
;; fix in-cone cpp peds

;; different agent (turtle) types
breed [ pedestrians pedestrian ]
breed [ cars car ]
breed [ crossing-detectors crossing-detector ]

pedestrians-own [
  start-pos
  dist-traveled
  walk-dir
  cpp-walking?
  fcfs-number
  start-tick
]
cars-own [
  start-pos
  has-stopped?
  has-crossed?
  drive-dir
  cpp-number
  fcfs-number
  start-tick
]

;; setup environment
to setup
  clear-all

  set crossing-ped-x? false
  set crossing-ped-y? false
  set crossing-car-x? false
  set crossing-car-y? false
  set cpp-next-car 0
  set cpp-total-cars 0
  set fcfs-next-agent 0
  set fcfs-total-agents 0
  set-default-shape pedestrians "person"
  set-default-shape cars "car"
  set-current-plot "Trip Times"
  set average-pedestrian-trip-time 0
  set average-car-trip-time 0
  set total-pedestrian-trip-time 0
  set total-car-trip-time 0
  set total-pedestrians 0
  set total-cars 0
  setup-background
  setup-detector-patches

  reset-ticks
end

to setup-background
  ask patches [
    set pcolor grey
    if pxcor > 55 and pxcor < 73 [ set pcolor black ]
    if pycor > 55 and pycor < 73 [ set pcolor black ]
    if pxcor = 64 or pycor = 64 [ set pcolor yellow ]
    if pycor > 74 and pycor < 82 and pxcor > 55 and pxcor < 73 [
      if pxcor mod 2 = 0 [ set pcolor white ]
    ]
    if pycor < 54 and pycor > 46 and pxcor > 55 and pxcor < 73 [
      if pxcor mod 2 = 0 [ set pcolor white ]
    ]
    if pxcor < 54 and pxcor > 46 and pycor > 55 and pycor < 73 [
      if pycor mod 2 = 0 [ set pcolor white ]
    ]
    if pxcor > 74 and pxcor < 82 and pycor > 55 and pycor < 73 [
      if pycor mod 2 = 0 [ set pcolor white ]
    ]
    if pxcor > 55 and pxcor < 73 and (pycor = 83 or pycor = 45) [ set pcolor white ]
    if pycor > 55 and pycor < 73 and (pxcor = 45 or pxcor = 83) [ set pcolor white ]
  ]
end

to setup-detector-patches
  ;; need extra detectors for this behaviour
  ifelse behaviour = "Car Priority" [
    ask patches [
      if pxcor > 55 and pxcor < 73 and pycor > 20 and pycor < 108 [ sprout-crossing-detectors 1 [ setxy pxcor pycor set color pcolor ] ]
      if pxcor > 20 and pxcor < 56 and pycor > 55 and pycor < 73 [ sprout-crossing-detectors 1 [ setxy pxcor pycor set color pcolor ] ]
      if pxcor > 72 and pxcor < 108 and pycor > 55 and pycor < 73 [ sprout-crossing-detectors 1 [ setxy pxcor pycor set color pcolor ] ]
    ]
  ] [
    ask patches [
      if pxcor > 54 and pxcor < 74 and pycor > 44 and pycor < 84 [ sprout-crossing-detectors 1 [ setxy pxcor pycor set color pcolor ] ]
      if pxcor > 44 and pxcor < 55 and pycor > 54 and pycor < 74 [ sprout-crossing-detectors 1 [ setxy pxcor pycor set color pcolor ] ]
      if pxcor > 75 and pxcor < 84 and pycor > 54 and pycor < 74 [ sprout-crossing-detectors 1 [ setxy pxcor pycor set color pcolor ] ]
    ]
  ]
end

;; main loop
;;  uses different processes based on selected behaviour
to go
  if behaviour = "Pedestrian Priority" [ pedestrian-prio-procedure ]
  if behaviour = "Car Priority" [ car-prio-procedure ]
  if behaviour = "First-come, First-serve" [ FCFS-procedure ]
  tick
end

;; check who is crossing the intersection at given time
to update-status
  set ped-x-updated? false
  set ped-y-updated? false
  set car-x-updated? false
  set car-y-updated? false
  ask crossing-detectors [
    if any? pedestrians-here [
      ask pedestrians-here [
        ifelse walk-dir = "x"
          [ set crossing-ped-x? true set ped-x-updated? true ]
          [ set crossing-ped-y? true set ped-y-updated? true ]
      ]
    ]
    if any? cars-here [
      ask cars-here [
        ifelse drive-dir = "north" or drive-dir = "south"
          [ set crossing-car-y? true set car-y-updated? true ]
          [ set crossing-car-x? true set car-x-updated? true ]
      ]
    ]
  ]
  if not ped-x-updated? [ set crossing-ped-x? false ]
  if not ped-y-updated? [ set crossing-ped-y? false ]
  if not car-x-updated? [ set crossing-car-x? false ]
  if not car-y-updated? [ set crossing-car-y? false ]
end


;;
;; PEDESTRIAN PRIORITY
;;
to pedestrian-prio-procedure
  ppp-move-pedestrians
  ppp-move-cars
  ppp-add-pedestrian
  ppp-add-car
end

to ppp-move-pedestrians
  ask pedestrians [
    ;; reached destination
    if dist-traveled + pedestrian-speed >= 25 [
      update-status
      set-current-plot-pen "Pedestrians"
      plot ticks - start-tick
      set total-pedestrian-trip-time total-pedestrian-trip-time + (ticks - start-tick)
      set total-pedestrians total-pedestrians + 1
      set average-pedestrian-trip-time total-pedestrian-trip-time / total-pedestrians
      die
    ]
    ;; moving horizontally
    if walk-dir = "x" and not crossing-car-y? [
      forward pedestrian-speed
      set dist-traveled dist-traveled + pedestrian-speed
      update-status
    ]
    ;; moving vertically
    if walk-dir = "y" and not crossing-car-x? [
      forward pedestrian-speed
      set dist-traveled dist-traveled + pedestrian-speed
      update-status
    ]
  ]
end

to ppp-move-cars
  ask cars [
    ifelse has-crossed? [
      if not can-move? car-speed [
        set-current-plot-pen "Cars"
        plot ticks - start-tick
        set total-car-trip-time total-car-trip-time + (ticks - start-tick)
        set total-cars total-cars + 1
        set average-car-trip-time total-car-trip-time / total-cars
        die
      ]
      forward car-speed
    ] [
      ifelse not has-stopped? [
        ;; stop if about to cross line
        if drive-dir = "south" [ if ycor - car-speed <= 83 [ set has-stopped? true ] ]
        if drive-dir = "north" [ if ycor + car-speed >= 45 [ set has-stopped? true ] ]
        if drive-dir = "west" [ if xcor - car-speed <= 83 [ set has-stopped? true ] ]
        if drive-dir = "east" [ if xcor + car-speed >= 45 [ set has-stopped? true ] ]
        if not has-stopped? and not any? other cars in-cone 12 3 [ forward car-speed ]
      ] [
        if drive-dir = "south" and not crossing-ped-x? and not crossing-car-x? [
          if ycor - car-speed <= 45 [ set has-crossed? true ]
          forward car-speed
          update-status
        ]
        if drive-dir = "north" and not crossing-ped-x? and not crossing-car-x? [
          if ycor + car-speed >= 83 [ set has-crossed? true ]
          forward car-speed
          update-status
        ]
        if drive-dir = "west" and not crossing-ped-y? and not crossing-car-y? [
          if xcor - car-speed <= 45 [ set has-crossed? true ]
          forward car-speed
          update-status
        ]
        if drive-dir = "east" and not crossing-ped-y? and not crossing-car-y? [
          if xcor + car-speed >= 83 [ set has-crossed? true ]
          forward car-speed
          update-status
        ]
      ]
    ]
  ]
end

to ppp-add-pedestrian
  if random 100 < pedestrian-frequency [
    create-pedestrians 1 [
      set size 7
      set dist-traveled 0
      set start-tick ticks
      ;; set start spot and direction
      set start-pos random 8
      if start-pos = 0 [ setxy 49 79 facexy 77 79 set walk-dir "x" ]
      if start-pos = 1 [ setxy 77 79 facexy 49 79 set walk-dir "x" ]
      if start-pos = 2 [ setxy 77 79 facexy 77 49 set walk-dir "y" ]
      if start-pos = 3 [ setxy 77 49 facexy 77 79 set walk-dir "y" ]
      if start-pos = 4 [ setxy 77 49 facexy 49 49 set walk-dir "x" ]
      if start-pos = 5 [ setxy 49 49 facexy 77 49 set walk-dir "x" ]
      if start-pos = 6 [ setxy 49 49 facexy 49 79 set walk-dir "y" ]
      if start-pos = 7 [ setxy 49 79 facexy 49 49 set walk-dir "y" ]
    ]
  ]
end

to ppp-add-car
  if random 100 < car-frequency [
    create-cars 1 [
      set size 7
      set has-stopped? false  ;; at stop sign
      set has-crossed? false  ;; crossed the intersection
      set start-tick ticks
      ;; set starting point
      set start-pos random 4
      if start-pos = 0 [ setxy 60 127 facexy 60 0 set drive-dir "south" ]
      if start-pos = 1 [ setxy 68 0 facexy 68 127 set drive-dir "north" ]
      if start-pos = 2 [ setxy 127 68 facexy 0 68 set drive-dir "west" ]
      if start-pos = 3 [ setxy 0 60 facexy 127 60 set drive-dir "east" ]
    ]
  ]
end
;;
;;
;;



;;
;;  CAR PRIORITY
;;
to car-prio-procedure
  cpp-move-cars
  cpp-move-pedestrians
  cpp-add-car
  cpp-add-pedestrian
end

to cpp-move-cars
  ask cars [
    ifelse has-crossed? [
      if not can-move? car-speed [
        update-status
        set-current-plot-pen "Cars"
        plot ticks - start-tick
        set total-car-trip-time total-car-trip-time + (ticks - start-tick)
        set total-cars total-cars + 1
        set average-car-trip-time total-car-trip-time / total-cars
        die
      ]
      forward car-speed
    ] [
      ifelse not has-stopped? [
        if drive-dir = "south" [ if ycor - car-speed <= 83 [ set has-stopped? true ] ]
        if drive-dir = "north" [ if ycor + car-speed >= 45 [ set has-stopped? true ] ]
        if drive-dir = "west" [ if xcor - car-speed <= 83 [ set has-stopped? true ] ]
        if drive-dir = "east" [ if xcor + car-speed >= 45 [ set has-stopped? true ] ]
        if not has-stopped? and not any? other cars in-cone 12 3 [ forward car-speed ]
      ] [
        ;; at stop sign, only first car goes
        if cpp-number = cpp-next-car [
          if drive-dir = "south" and not crossing-ped-x? [
            if ycor - car-speed <= 45 [ set has-crossed? true set cpp-next-car cpp-next-car + 1 ]
            forward car-speed
            update-status
          ]
          if drive-dir = "north" and not crossing-ped-x? [
            if ycor + car-speed >= 83 [ set has-crossed? true set cpp-next-car cpp-next-car + 1 ]
            forward car-speed
            update-status
          ]
          if drive-dir = "west" and not crossing-ped-y? [
            if xcor - car-speed <= 45 [ set has-crossed? true set cpp-next-car cpp-next-car + 1 ]
            forward car-speed
            update-status
          ]
          if drive-dir = "east" and not crossing-ped-y? [
            if xcor + car-speed >= 83 [ set has-crossed? true set cpp-next-car cpp-next-car + 1 ]
            forward car-speed
            update-status
          ]
        ]
      ]
    ]
  ]
end

to cpp-move-pedestrians
  ask pedestrians [
    ;; reached destination
    if dist-traveled + pedestrian-speed >= 25 [
      update-status
      set-current-plot-pen "Pedestrians"
      plot ticks - start-tick
      set total-pedestrian-trip-time total-pedestrian-trip-time + (ticks - start-tick)
      set total-pedestrians total-pedestrians + 1
      set average-pedestrian-trip-time total-pedestrian-trip-time / total-pedestrians
      die
    ]
    if cpp-walking? or not crossing-car-y? [
      set cpp-walking? true
      forward pedestrian-speed
      set dist-traveled dist-traveled + pedestrian-speed
      update-status
    ]
  ]
end

to cpp-add-car
  if random 100 < car-frequency [
    create-cars 1 [
      set size 7
      set has-stopped? false
      set has-crossed? false
      set cpp-number cpp-total-cars
      set cpp-total-cars cpp-total-cars + 1
      set start-tick ticks
      ;; set starting point
      set start-pos random 4
      if start-pos = 0 [ setxy 60 127 facexy 60 0 set drive-dir "south" ]
      if start-pos = 1 [ setxy 68 0 facexy 68 127 set drive-dir "north" ]
      if start-pos = 2 [ setxy 127 68 facexy 0 68 set drive-dir "west" ]
      if start-pos = 3 [ setxy 0 60 facexy 127 60 set drive-dir "east" ]
    ]
  ]
end

to cpp-add-pedestrian
  if random 100 < pedestrian-frequency [
    create-pedestrians 1 [
      set size 7
      set dist-traveled 0
      set cpp-walking? false
      set start-tick ticks
      ;; set start spot and direction
      set start-pos random 8
      if start-pos = 0 [ setxy 49 79 facexy 77 79 set walk-dir "x" ]
      if start-pos = 1 [ setxy 77 79 facexy 49 79 set walk-dir "x" ]
      if start-pos = 2 [ setxy 77 79 facexy 77 49 set walk-dir "y" ]
      if start-pos = 3 [ setxy 77 49 facexy 77 79 set walk-dir "y" ]
      if start-pos = 4 [ setxy 77 49 facexy 49 49 set walk-dir "x" ]
      if start-pos = 5 [ setxy 49 49 facexy 77 49 set walk-dir "x" ]
      if start-pos = 6 [ setxy 49 49 facexy 49 79 set walk-dir "y" ]
      if start-pos = 7 [ setxy 49 79 facexy 49 49 set walk-dir "y" ]
    ]
  ]
end
;;
;;
;;



;;
;; FIRST-COME, FIRST-SERVE
;;
to FCFS-procedure
  fcfs-move-pedestrians
  fcfs-move-cars
  fcfs-add-pedestrians
  fcfs-add-cars
end

to fcfs-move-pedestrians
  ask pedestrians [
    ;; reached destination
    if dist-traveled + pedestrian-speed >= 25 [
      update-status
      set fcfs-next-agent fcfs-next-agent + 1
      set-current-plot-pen "Pedestrians"
      plot ticks - start-tick
      set total-pedestrian-trip-time total-pedestrian-trip-time + (ticks - start-tick)
      set total-pedestrians total-pedestrians + 1
      set average-pedestrian-trip-time total-pedestrian-trip-time / total-pedestrians
      die
    ]
    if fcfs-number = fcfs-next-agent [
      forward pedestrian-speed
      set dist-traveled dist-traveled + pedestrian-speed
      update-status
    ]
  ]
end

to fcfs-move-cars
  ask cars [
    ifelse has-crossed? [
      if not can-move? car-speed [
        set-current-plot-pen "Cars"
        plot ticks - start-tick
        set total-car-trip-time total-car-trip-time + (ticks - start-tick)
        set total-cars total-cars + 1
        set average-car-trip-time total-car-trip-time / total-cars
        die
      ]
      forward car-speed
    ] [
      ifelse not has-stopped? [
        if drive-dir = "south" [ if ycor - car-speed <= 83 [ set has-stopped? true set fcfs-number fcfs-total-agents set fcfs-total-agents fcfs-total-agents + 1 ] ]
        if drive-dir = "north" [ if ycor + car-speed >= 45 [ set has-stopped? true set fcfs-number fcfs-total-agents set fcfs-total-agents fcfs-total-agents + 1 ] ]
        if drive-dir = "west" [ if xcor - car-speed <= 83 [ set has-stopped? true set fcfs-number fcfs-total-agents set fcfs-total-agents fcfs-total-agents + 1 ] ]
        if drive-dir = "east" [ if xcor + car-speed >= 45 [ set has-stopped? true set fcfs-number fcfs-total-agents set fcfs-total-agents fcfs-total-agents + 1 ] ]
        if not has-stopped? and not any? other cars in-cone 12 3 [ forward car-speed ]
      ] [
        if fcfs-number = fcfs-next-agent [
          if drive-dir = "south" [
            if ycor - car-speed <= 45 [ set has-crossed? true set fcfs-next-agent fcfs-next-agent + 1 ]
            forward car-speed
            update-status
          ]
          if drive-dir = "north" [
            if ycor + car-speed >= 83 [ set has-crossed? true set fcfs-next-agent fcfs-next-agent + 1 ]
            forward car-speed
            update-status
          ]
          if drive-dir = "west" [
            if xcor - car-speed <= 45 [ set has-crossed? true set fcfs-next-agent fcfs-next-agent + 1 ]
            forward car-speed
            update-status
          ]
          if drive-dir = "east" [
            if xcor + car-speed >= 83 [ set has-crossed? true set fcfs-next-agent fcfs-next-agent + 1 ]
            forward car-speed
            update-status
          ]
        ]
      ]
    ]
  ]
end

to fcfs-add-pedestrians
  if random 100 < pedestrian-frequency [
    create-pedestrians 1 [
      set size 7
      set dist-traveled 0
      set fcfs-number fcfs-total-agents
      set fcfs-total-agents fcfs-total-agents + 1
      set start-tick ticks
      ;; set start spot and direction
      set start-pos random 8
      if start-pos = 0 [ setxy 49 79 facexy 77 79 set walk-dir "x" ]
      if start-pos = 1 [ setxy 77 79 facexy 49 79 set walk-dir "x" ]
      if start-pos = 2 [ setxy 77 79 facexy 77 49 set walk-dir "y" ]
      if start-pos = 3 [ setxy 77 49 facexy 77 79 set walk-dir "y" ]
      if start-pos = 4 [ setxy 77 49 facexy 49 49 set walk-dir "x" ]
      if start-pos = 5 [ setxy 49 49 facexy 77 49 set walk-dir "x" ]
      if start-pos = 6 [ setxy 49 49 facexy 49 79 set walk-dir "y" ]
      if start-pos = 7 [ setxy 49 79 facexy 49 49 set walk-dir "y" ]
    ]
  ]
end

to fcfs-add-cars
  if random 100 < car-frequency [
    create-cars 1 [
      set size 7
      set has-stopped? false
      set has-crossed? false
      set start-tick ticks
      ;; set starting point
      set start-pos random 4
      if start-pos = 0 [ setxy 60 127 facexy 60 0 set drive-dir "south" ]
      if start-pos = 1 [ setxy 68 0 facexy 68 127 set drive-dir "north" ]
      if start-pos = 2 [ setxy 127 68 facexy 0 68 set drive-dir "west" ]
      if start-pos = 3 [ setxy 0 60 facexy 127 60 set drive-dir "east" ]
    ]
  ]
end
;;
;;
;;
@#$#@#$#@
GRAPHICS-WINDOW
271
10
666
406
-1
-1
3.0
1
10
1
1
1
0
0
0
1
0
128
0
128
1
1
1
ticks
30.0

BUTTON
4
10
70
43
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
76
10
139
43
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
4
46
151
79
pedestrian-frequency
pedestrian-frequency
0
10
5.0
1
1
NIL
HORIZONTAL

SLIDER
156
46
262
79
car-frequency
car-frequency
0
10
5.0
1
1
NIL
HORIZONTAL

SLIDER
4
83
132
116
pedestrian-speed
pedestrian-speed
1
5
3.0
1
1
NIL
HORIZONTAL

SLIDER
136
83
228
116
car-speed
car-speed
5
10
6.0
1
1
NIL
HORIZONTAL

CHOOSER
3
121
195
166
behaviour
behaviour
"Pedestrian Priority" "Car Priority" "First-come, First-serve"
0

PLOT
3
170
263
326
Trip Times
Time (ticks)
Frequency
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Pedestrians" 1.0 0 -13345367 true "" ""
"Cars" 1.0 0 -2674135 true "" ""

MONITOR
3
330
207
375
Average Pedestrian Trip Time (ticks)
average-pedestrian-trip-time
0
1
11

MONITOR
3
379
172
424
Average Car Trip Time (ticks)
average-car-trip-time
0
1
11

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
