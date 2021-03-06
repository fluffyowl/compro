import std.stdio, std.array, std.string, std.conv, std.algorithm;
import std.typecons, std.range, std.random, std.math, std.container;
import std.numeric, std.bigint, core.bitop, std.bitmanip;

immutable long MOD = 10^^9 + 7;
immutable long INF = 1L << 59;

void main() {
    auto T = readln.chomp;
    string S = "";
    foreach_reverse (c; T) S ~= c;
    auto N = S.length.to!int;

    auto P = new long[](N+1);
    P[0] = 1;
    foreach (i; 0..N) P[i+1] = P[i] * 26 % MOD;
    long ans = P[N];

    auto sa = suffixArray(S);
    int start = 1;

    foreach (i; 1..N+1) {
        if (i == 1 || sa.lcp[i-1] < N - sa.sa[start]) {
            ans -= P[sa.sa[i]];
            ans %= MOD;
            start = i;
        }
    }

    ans = (ans + MOD) % MOD;
    ans.writeln;
}

struct SA(T) {
    T[] s; /// base string
    int[] sa; /// suffix array
    int[] rsa; /// reverse sa, rsa[sa[i]] == i
    int[] lcp; /// lcp
    this(in T[] s) {
        size_t n = s.length;
        this.s = s.dup;
        sa = new int[](n+1);
        rsa = new int[](n+1);
        lcp = new int[](n);
    }
}

int[] sais(T)(in T[] _s, int B = 200) {
    import std.conv, std.algorithm, std.range;
    int n = _s.length.to!int;
    int[] sa = new int[](n+1);
    if (n == 0) return sa;

    auto s = _s.map!"a+1".array ~ T(0); B++; // add 0 to last
    // ls
    bool[] ls = new bool[](n+1);
    ls[n] = true;
    foreach_reverse (i; 0..n) {
        ls[i] = (s[i] == s[i+1]) ? ls[i+1] : (s[i] < s[i+1]);
    }
    // sum(l[0], s[0], l[1], s[1], ...)
    int[] sumL = new int[](B+1), sumS = new int[](B+1);
    s.each!((i, c) => !ls[i] ? sumS[c]++ : sumL[c+1]++);
    foreach (i; 0..B) {
        sumL[i+1] += sumS[i];
        sumS[i+1] += sumL[i+1];
    }

    void induce(in int[] lms) {
        sa[] = -1;
        auto buf0 = sumS.dup;
        foreach (d; lms) {
            sa[buf0[s[d]]++] = d;
        }
        auto buf1 = sumL.dup;
        foreach (v; sa) {
            if (v >= 1 && !ls[v-1]) {
                sa[buf1[s[v-1]]++] = v-1;
            }
        }
        auto buf2 = sumL.dup;
        foreach_reverse (v; sa) {
            if (v >= 1 && ls[v-1]) {
                sa[--buf2[s[v-1]+1]] = v-1;
            }
        }
    }

    int[] lms = iota(1, n+1).filter!(i => !ls[i-1] && ls[i]).array;
    int[] lmsMap = new int[](n+1);
    lmsMap[] = -1; lms.each!((i, v) => lmsMap[v] = i.to!int);

    induce(lms);

    if (lms.length >= 2) {
        int m = lms.length.to!int - 1;
        // sort lms
        auto lms2 = sa.filter!(v => lmsMap[v] != -1).array;
        int recN = 1;
        int[] recS = new int[](m);
        recS[lmsMap[lms2[1]]] = 1;
        foreach (i; 2..m+1) {
            int l = lms2[i-1], r = lms2[i];
            int nl = lms[lmsMap[l]+1], nr = lms[lmsMap[r]+1];
            if (cmp(s[l..nl+1], s[r..nr+1])) recN++;
            recS[lmsMap[lms2[i]]] = recN;
        }
        //re induce
        induce(lms.indexed(sais!int(recS, recN)).array);
    }

    return sa;
}


/// return SA!T. each character must be inside [T(0), T(B)).
SA!T suffixArray(T)(in T[] _s, int B = 200) {
    import std.conv, std.algorithm;
    int n = _s.length.to!int;
    auto saInfo = SA!T(_s);
    if (n == 0) return saInfo;

    with (saInfo) {
        sa = sais(_s, B);
        //rsa
        sa.each!((i, v) => rsa[v] = i.to!int);
        //lcp
        int h = 0;
        foreach (i; 0..n) {
            int j = sa[rsa[i]-1];
            if (h > 0) h--;
            for (; j+h < n && i+h < n; h++) {
                if (s[j+h] != s[i+h]) break;
            }
            lcp[rsa[i]-1] = h;
        }
    }
    return saInfo;
}
