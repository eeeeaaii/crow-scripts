-- Weird Area - Experiment 21
-- https://www.youtube.com/watch?v=1e7jfzmljyA
-- begins around 1:40 and ends around 3:25
--
-- This script implements a random walk using three-note figures.
-- Each figure is essentially a random permutation of three pitches,
-- where the pitches are next to each other in a scale.
-- So for for example, since D, E, F are next to each other in
-- C major, permutations would include DEF, EFD, DFE, etc.
-- Notes are played in sync with an incoming clock signal.
-- After playing the three pitches in the figure, and resting for one
-- clock tick, the algorithm looks at the last pitch that was played.
-- The next figure will have that pitch as the top, middle, or bottom
-- pitch (chosen also at random).
-- The scale is an alternate pentatonic scale (C D F G Bb).


scale = { 0, 2, 5, 7, 10 }
index = 1
counter = 1
start = 84
all_notes = {}
currentFigure = nil

-- Initialize by transposing the scale into 4 different octaves
-- to give an array of possible note values.
function init()
	input[1].mode('change', 1.0, 0.1, 'rising');
	output[1].slew = 0
	for i = -2, 2 do
		for j = 1, #scale do
			noteval =  i * 12 + scale[j] + start
			all_notes[#all_notes + 1] = noteval
		end
	end
end

-- Convert note numbers to volts (I couldn't find a library function
-- to do this, maybe I didn't look hard enough)
function nnToVolt(n)
	return (n - 60) / 12
end

-- When a clock is received, if we are playing the first note in a figure,
-- decide what the figure will be and play the first note in it.
-- Otherwise just play the next note in the figure, or rest if it's time to rest.
input[1].change = function()
	if counter == 1 then
		currentFigure = getNextFigure()
		output[1].volts = nnToVolt(currentFigure[1])
	elseif counter == 2 then
		output[1].volts = nnToVolt(currentFigure[2])
	elseif counter == 3 then
		output[1].volts = nnToVolt(currentFigure[3])
	end

	counter = counter + 1
	if counter == 4 then
		counter = 1
	end
end


-- Decide on what the next figure will be.
function getNextFigure()

    -- Get the 3 consecutive pitches in the scale starting at index.
	a = all_notes[index]
	b = all_notes[index + 1]
	c = all_notes[index + 2]

	r = {}

	z = math.random(6)

	lastIndexOfFigure = nil

    -- Choose a random permutation to play.
	if z == 1 then
		r = {a, b, c}
		lastIndexOfFigure = index + 2
	elseif z == 2 then
		r = {a, c, b}
		lastIndexOfFigure = index + 1
	elseif z == 3 then
		r = {b, a, c}
		lastIndexOfFigure = index + 2
	elseif z == 4 then
		r = {b, c, a}
		lastIndexOfFigure = index
	elseif z == 5 then
		r = {c, a, b}
		lastIndexOfFigure = index + 1
	else
		r = {c, b, a}
		lastIndexOfFigure = index
	end

	nextIndex = 0
	rn = math.random(3)

    -- lastIndexOfFigure is the last pitch
    -- that was played. The next figure includes
    -- that pitch...
	if rn == 1 then
		-- ...as its top pitch.
		nextIndex = lastIndexOfFigure - 2
	elseif rn == 2 then
		-- ...as its middle pitch.
		nextIndex = lastIndexOfFigure - 1
	else
		-- ...as its bottom pitch.
		nextIndex = lastIndexOfFigure
	end

    -- deal with boundary conditions so we don't
    -- walk out of the 4-octave range. It sounds
    -- bad if you loop around so we will just
    -- stop at the boundary and wait for the
    -- walk to take us back down.
	if nextIndex < 1 then
		nextIndex = 1
	end
	if nextIndex > (#all_notes - 3) then
		nextIndex = (#all_notes - 3)
	end

	index = nextIndex

	return r
end