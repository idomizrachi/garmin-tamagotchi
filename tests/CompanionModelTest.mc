import Toybox.Test;

(:test)
function lateWorkoutYieldsToSleep(logger) {
    var m = new CompanionModel(); m.rollover(20261105); m.finishHistorySeed();
    m.observeWorkout(10000, 13000, 1, 13100);
    Test.assert(!m.isNight(1380, 13100));
    Test.assert(m.isNight(1400, 15000));
    Test.assert(m.isNight(180, 15000));
    return true;
}

(:test)
function missedWorkoutDoesNotRestartRecovery(logger) {
    var m = new CompanionModel(); m.rollover(20261105); m.finishHistorySeed();
    m.observeWorkout(10000, 11000, 1, 19000);
    m.beginGlance(19000, 1080);
    Test.assertEqual(m.pose(19000, 1080, 0, true), m.CELEBRATE);
    Test.assert(m.pose(19005, 1080, 0, true) != m.WATER);
    Test.assertEqual(m.workoutCheers, 2);
    m.beginGlance(19001, 1080);
    Test.assertEqual(m.workoutCheers, 2);
    m.beginGlance(19100, 1081);
    Test.assertEqual(m.workoutCheers, 1);
    return true;
}

(:test)
function firstInstallDoesNotReplayOldWorkouts(logger) {
    var m = new CompanionModel(); m.rollover(20261105);
    m.observeWorkout(10000, 11000, 1, 19000); m.finishHistorySeed();
    Test.assertEqual(m.workoutCheers, 0);
    m.observeWorkout(15000, 18000, 2, 19000);
    Test.assertEqual(m.workoutCheers, 3);
    Test.assertEqual(m.workoutSport, 2);
    return true;
}

(:test)
function persistencePreventsDuplicateCelebration(logger) {
    var m = new CompanionModel(); m.rollover(20261105); m.finishHistorySeed();
    m.observeWorkout(10000, 11000, 1, 12000); m.beginGlance(12000, 800);
    var restored = new CompanionModel(); restored.restore(m.snapshot());
    restored.observeWorkout(10000, 11000, 1, 13000);
    Test.assertEqual(restored.workoutCheers, 2);
    restored.rollover(20261106);
    Test.assertEqual(restored.workoutCheers, 0);
    Test.assert(restored.historySeeded);
    return true;
}

(:test)
function goalsAndUnavailableData(logger) {
    var m = new CompanionModel(); m.rollover(20261105);
    m.observeSteps(null, 9000); Test.assert(!m.goalSeen);
    m.observeSteps(9000, 9000); Test.assert(m.goalSeen);
    m.stepCheers = 0; m.observeSteps(10000, 9000); Test.assertEqual(m.stepCheers, 0);
    m.rollover(20261106); Test.assert(!m.goalSeen);
    m.observeSteps(8000, 8000); Test.assertEqual(m.stepCheers, 3);
    return true;
}

(:test)
function nightDoesNotConsumeCheers(logger) {
    var m = new CompanionModel(); m.rollover(20261105); m.workoutCheers = 3;
    m.beginGlance(20000, 180);
    Test.assertEqual(m.workoutCheers, 3);
    Test.assertEqual(m.pose(20000, 180, 0, true), m.SLEEP);
    return true;
}

(:test)
function movementDoesNotDelayBedtime(logger) {
    var m = new CompanionModel(); m.rollover(20261105);
    m.observeMovement(150, 120, 20000);
    Test.assertEqual(m.pose(20001, 900, 0, true), m.WALK);
    Test.assertEqual(m.pose(20001, 1400, 0, true), m.SLEEP);
    m.observeMovement(2000, 3600, 22000); Test.assertEqual(m.movementUntil, 20180);
    return true;
}

(:test)
function unknownAndInvalidWorkoutsStayOrdinary(logger) {
    var m = new CompanionModel(); m.rollover(20261105); m.finishHistorySeed();
    m.observeWorkout(10000, 11000, 0, 12000);
    m.observeWorkout(10000, 13000, 1, 12000);
    m.observeWorkout(10000, 9000, 2, 12000);
    Test.assertEqual(m.workoutCheers, 0);
    Test.assertEqual(m.workoutStart, 0);
    return true;
}

(:test)
function heldPropsDoNotDuplicateLingeringProps(logger) {
    var m = new CompanionModel(); m.prop = 1; m.propUntil = 20000;
    Test.assertEqual(m.currentProp(15000, m.COFFEE), 0);
    Test.assertEqual(m.currentProp(15000, m.IDLE), 1);
    m.workoutEnd = 14000;
    Test.assertEqual(m.currentProp(15000, m.IDLE), 2);
    Test.assertEqual(m.currentProp(15000, m.WATER), 0);
    return true;
}

(:test)
function invalidSettingsAndCorruptStorageAreIgnored(logger) {
    var m = new CompanionModel(); m.setSchedule(1400, 100, 50);
    Test.assertEqual(m.wakeMinute, 420);
    Test.assertEqual(m.bedMinute, 1365);
    m.restore({"day" => "broken"});
    Test.assertEqual(m.day, 0);
    m.setSchedule(390, 1200, 1380);
    Test.assertEqual(m.wakeMinute, 390);
    return true;
}
