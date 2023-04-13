
TEST_FILE="Cargo.toml";
TEST_RESULT=0; 
for dir in ./contracts/*/; 
do
    echo "${dir}";
    dir=${dir%*/};
    if [ ! -f "$dir/$TEST_FILE" ]; then
        continue;
    fi
    cd $dir;
    forc build;
    forc test;
    TEST_RESULT=$? || $TEST_RESULT;
    cargo test;
    TEST_RESULT=$? || $TEST_RESULT;
    cd ../../;
done
echo "Testing Finished!";
echo $TEST_RESULT;
exit $TEST_RESULT;